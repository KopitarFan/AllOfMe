# All Of Me Website

This directory is the public static website source for All Of Me.

Keep `site/` separate from `docs/`:

- `site/` is public marketing, support, privacy, and user documentation.
- `docs/` is internal project documentation, release planning, runbooks, and App
  Store preparation notes.

The site is plain HTML and CSS by design. It does not use analytics, cookies,
third-party scripts, or a build step.

Suggested deployment:

1. Deploy the contents of `site/` to GitHub Pages or another static host.
2. Point `allofmeapp.com` at the static host when DNS is ready.
3. Use these public URLs in App Store Connect:
   - Privacy Policy URL: `https://allofmeapp.com/privacy-policy.html`
   - Support URL: `https://allofmeapp.com/support.html`
   - Marketing URL: `https://allofmeapp.com/`

