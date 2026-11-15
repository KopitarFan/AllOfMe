"""Check the production Swift models without an iOS simulator."""
from pathlib import Path
import subprocess
import tempfile

source = (Path(__file__).resolve().parents[1] / "AllOfMeCompanion/AllOfMeCompanionApp.swift").read_text()
models = source[source.index("struct FrontGroup:"):source.index("private struct Pairing:")]
checks = r'''
let decoder = JSONDecoder()
let legacy = try decoder.decode(SharedFront.self, from: Data("""
{"paused":false,"status":{"eventId":"old","changedAt":"2026-11-14T12:00:00Z","members":[{"name":"A"}]}}
""".utf8))
precondition(legacy.status!.members[0].groups == nil)
precondition(legacy.status!.members[0].photoData == nil)
precondition(legacy.status!.members[0].description == nil)
precondition(legacy.status!.date != nil)
let current = try decoder.decode(SharedFront.self, from: Data("""
{"paused":false,"status":{"eventId":"new","changedAt":"2026-11-14T12:00:00.000Z","members":[{"id":"part-a","name":"A","role":"Protector","description":"A description.","colorValue":4280588397,"groups":[{"id":"g1","name":"Daily life","colorValue":4287333366}],"imageDataUri":"data:image/png;base64,aGVsbG8="},{"id":"part-b","name":"B"}]}}
""".utf8))
precondition(current.status!.members.count == 2)
precondition(current.status!.members[0].groups!.first!.name == "Daily life")
precondition(current.status!.members[0].description == "A description.")
precondition(current.status!.members[0].photoData == Data("hello".utf8))
precondition(current.status!.members[1].photoData == nil)
let paused = try decoder.decode(SharedFront.self, from: Data("""
{"paused":true,"status":null}
""".utf8))
precondition(paused.paused && paused.status == nil)
print("Passed: legacy profiles, rich profiles, multiple fronts, pictures, groups, timestamps, paused status.")
'''
with tempfile.TemporaryDirectory(prefix="aom-profile-decoding-") as directory:
    script = Path(directory) / "check.swift"
    script.write_text("import Foundation\n" + models + "\n" + checks)
    subprocess.run(["swift", "-module-cache-path", directory, str(script)], check=True)
