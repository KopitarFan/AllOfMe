import SwiftUI
import UserNotifications
import Security

struct FrontMember: Decodable { let name: String }
struct FrontStatus: Decodable {
    let eventId: String
    let changedAt: String
    let members: [FrontMember]
    var date: Date? {
        let fractional = ISO8601DateFormatter()
        fractional.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return fractional.date(from: changedAt) ?? ISO8601DateFormatter().date(from: changedAt)
    }
}
struct SharedFront: Decodable {
    let paused: Bool
    let status: FrontStatus?
}
private struct Pairing: Codable {
    let recipientId: String
    let token: String
}

private enum CredentialStore {
    static let service = "com.allofme.companion.pairing"
    static func load() throws -> Data? {
        var result: CFTypeRef?
        let status = SecItemCopyMatching([
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: service,
            kSecAttrAccount: "receiver",
            kSecReturnData: true,
            kSecMatchLimit: kSecMatchLimitOne
        ] as CFDictionary, &result)
        if status == errSecItemNotFound { return nil }
        guard status == errSecSuccess, let data = result as? Data else {
            throw NSError(domain: NSOSStatusErrorDomain, code: Int(status))
        }
        return data
    }
    static func save(_ data: Data) throws {
        let query = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: service,
            kSecAttrAccount: "receiver"
        ] as [String: Any]
        let attributes = [
            kSecValueData: data,
            kSecAttrAccessible: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
        ] as [String: Any]
        let update = SecItemUpdate(query as CFDictionary, attributes as CFDictionary)
        if update == errSecItemNotFound {
            var item = query
            item.merge(attributes) { _, new in new }
            let status = SecItemAdd(item as CFDictionary, nil)
            guard status == errSecSuccess else { throw NSError(domain: NSOSStatusErrorDomain, code: Int(status)) }
        } else if update != errSecSuccess {
            throw NSError(domain: NSOSStatusErrorDomain, code: Int(update))
        }
    }
    static func clear() throws {
        let status = SecItemDelete([
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: service,
            kSecAttrAccount: "receiver"
        ] as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw NSError(domain: NSOSStatusErrorDomain, code: Int(status))
        }
    }
}

@MainActor
final class CompanionModel: ObservableObject {
    static let shared = CompanionModel()
    @Published private(set) var paired = false
    @Published private(set) var front: SharedFront?
    @Published private(set) var fetchedAt: Date?
    @Published private(set) var busy = false
    @Published var message: String?
    @Published var notificationsEnabled = false
    private var pairing: Pairing?
    private var pushToken: String?
    private let baseURL: URL

    private init() {
        let configured = Bundle.main.object(forInfoDictionaryKey: "SharingBaseURL") as? String ?? ""
        guard let url = URL(string: configured), url.scheme == "https", url.host != nil,
              url.user == nil, url.password == nil, url.query == nil, url.fragment == nil else {
            fatalError("SharingBaseURL must be an HTTPS URL.")
        }
        baseURL = url
        do {
            if let data = try CredentialStore.load() {
                pairing = try JSONDecoder().decode(Pairing.self, from: data)
                paired = true
            }
        } catch { message = "Could not unlock the saved connection. Reopen the app after unlocking your phone." }
    }

    private func request(_ path: String, method: String = "GET", body: [String: String]? = nil, authenticated: Bool = true) async throws -> Data {
        let url = baseURL.appendingPathComponent("v1/front-sharing").appendingPathComponent(path)
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.timeoutInterval = 15
        request.cachePolicy = .reloadIgnoringLocalCacheData
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if authenticated {
            guard let pairing else { throw URLError(.userAuthenticationRequired) }
            request.setValue("Bearer " + pairing.token, forHTTPHeaderField: "Authorization")
        }
        if let body { request.httpBody = try JSONSerialization.data(withJSONObject: body) }
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let response = response as? HTTPURLResponse else { throw URLError(.badServerResponse) }
        if response.statusCode == 401 {
            try CredentialStore.clear()
            pairing = nil
            paired = false
            front = nil
            fetchedAt = nil
            throw URLError(.userAuthenticationRequired)
        }
        guard (200..<300).contains(response.statusCode) else { throw URLError(.badServerResponse) }
        return data
    }

    func pair(code: String) async {
        guard !busy else { return }
        busy = true
        message = nil
        defer { busy = false }
        do {
            let data = try await request("pair", method: "POST", body: ["code": code.trimmingCharacters(in: .whitespacesAndNewlines)], authenticated: false)
            let result = try JSONDecoder().decode(Pairing.self, from: data)
            try CredentialStore.save(try JSONEncoder().encode(result))
            pairing = result
            paired = true
            await refresh()
            await enableNotifications()
        } catch { message = "Could not connect. Check the invitation or ask for a new one." }
    }

    func refresh() async {
        guard paired else { return }
        do {
            let data = try await request("current")
            front = try JSONDecoder().decode(SharedFront.self, from: data)
            fetchedAt = Date()
            message = nil
        } catch {
            message = paired
                ? "Could not refresh. Any status below may be out of date."
                : "This connection is no longer available. Ask for a new invitation."
        }
    }

    func enableNotifications() async {
        do {
            _ = try await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge])
            await updateNotificationSettings()
            UIApplication.shared.registerForRemoteNotifications()
        } catch { message = "Notifications could not be enabled. You can still refresh here." }
    }

    func updateNotificationSettings() async {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        notificationsEnabled = settings.authorizationStatus == .authorized || settings.authorizationStatus == .provisional
    }

    func receivedPushToken(_ token: String) async {
        pushToken = token
        await registerPushToken()
    }

    func registerPushToken() async {
        guard paired, let pushToken else { return }
        #if DEBUG
        let environment = "sandbox"
        #else
        let environment = "production"
        #endif
        do {
            _ = try await request("device", method: "PUT", body: ["token": pushToken, "environment": environment])
        } catch { message = "Notification setup is pending. Reopen the app to retry." }
    }

    func disconnect() async {
        guard !busy else { return }
        busy = true
        defer { busy = false }
        do {
            _ = try await request("device", method: "DELETE")
            try CredentialStore.clear()
            pairing = nil
            paired = false
            front = nil
            fetchedAt = nil
            message = nil
            UNUserNotificationCenter.current().removeAllDeliveredNotifications()
        } catch { message = "Could not disconnect. Try again when online." }
    }
}

final class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        UNUserNotificationCenter.current().delegate = self
        application.registerForRemoteNotifications()
        return true
    }

    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        let token = deviceToken.map { String(format: "%02x", $0) }.joined()
        Task { @MainActor in await CompanionModel.shared.receivedPushToken(token) }
    }

    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        Task { @MainActor in
            CompanionModel.shared.message = "Push registration is unavailable. You can still refresh the app."
        }
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .sound])
        Task { @MainActor in await CompanionModel.shared.refresh() }
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        Task { @MainActor in
            await CompanionModel.shared.refresh()
            completionHandler()
        }
    }
}

@main
struct AllOfMeCompanionApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    @StateObject private var model = CompanionModel.shared
    @Environment(\.scenePhase) private var phase

    var body: some Scene {
        WindowGroup {
            CompanionView(model: model)
                .task { await model.refresh(); await model.updateNotificationSettings() }
                .onChange(of: phase) { _, value in
                    if value == .active {
                        Task {
                            await model.refresh()
                            await model.updateNotificationSettings()
                            await model.registerPushToken()
                        }
                    }
                }
        }
    }
}

struct CompanionView: View {
    @ObservedObject var model: CompanionModel
    @State private var code = ""
    @State private var confirmDisconnect = false

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Label("A little closer, wherever you are.", systemImage: "heart.circle.fill")
                        .font(.title3).foregroundStyle(.teal)
                }
                if model.paired {
                    Section("Current front") {
                        if let front = model.front {
                            if front.paused {
                                Label("Sharing is paused", systemImage: "pause.circle")
                            } else if let status = front.status {
                                if status.members.isEmpty {
                                    Text("No one is marked as fronting")
                                }
                                ForEach(Array(status.members.enumerated()), id: \.offset) { _, member in
                                    Label(member.name, systemImage: "person.crop.circle")
                                        .font(.title2)
                                }
                                if let date = status.date {
                                    Text("Updated \(date.formatted(date: .abbreviated, time: .shortened))")
                                        .font(.footnote).foregroundStyle(.secondary)
                                }
                            } else {
                                Text("Waiting for a shared update")
                            }
                        } else { Text("Checking for an update…") }
                        if let fetchedAt = model.fetchedAt {
                            Text("Last checked \(fetchedAt.formatted(date: .omitted, time: .shortened))")
                                .font(.caption).foregroundStyle(.secondary)
                        }
                        Button("Refresh", systemImage: "arrow.clockwise") {
                            Task { await model.refresh() }
                        }
                    }
                    Section("Notifications") {
                        Text(model.notificationsEnabled ? "Notifications are enabled" : "Notifications are off")
                        if !model.notificationsEnabled {
                            Button("Enable notifications") { Task { await model.enableNotifications() } }
                            Link("Open Settings", destination: URL(string: UIApplication.openSettingsURLString)!)
                        }
                        Text("Notifications contain a discreet update message. Open the app to see details.")
                            .font(.footnote).foregroundStyle(.secondary)
                    }
                    Section {
                        Button("Disconnect", role: .destructive) { confirmDisconnect = true }
                            .disabled(model.busy)
                    }
                } else {
                    Section("Connect with an invitation") {
                        Text("In All Of Me, open Settings & privacy → Front sharing and create an invitation.")
                        TextField("Invitation code", text: $code)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                            .privacySensitive()
                        Button("Connect") { Task { await model.pair(code: code); if model.paired { code = "" } } }
                            .disabled(model.busy || code.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }
                }
                if model.busy { ProgressView() }
                if let message = model.message {
                    Section { Text(message).foregroundStyle(.secondary) }
                }
            }
            .navigationTitle("All Of Me")
            .refreshable { await model.refresh() }
            .confirmationDialog("Disconnect from shared updates?", isPresented: $confirmDisconnect) {
                Button("Disconnect", role: .destructive) { Task { await model.disconnect() } }
            }
        }
        .tint(.teal)
        .privacySensitive()
    }
}
