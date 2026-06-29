# All Of Me Website

This directory is the public static website source for All Of Me.

Keep `site/` separate from `docs/`:

- `site/` is public marketing, support, privacy, and user documentation.
- `docs/` is internal project documentation, release planning, runbooks, and App
  Store preparation notes.

The site is plain HTML and CSS by design. It does not use analytics, cookies,
third-party scripts, or a build step.

Deployment:

1. The `Site Deploy` GitHub Actions workflow syncs the contents of `site/` to
   the production VPS with `rsync` over SSH.
2. The workflow runs automatically when changes under `site/` are merged to
   `main`. It can also be run manually from GitHub Actions.
3. The workflow reuses the production SSH secrets:
   - `ALLOFME_DEPLOY_HOST`
   - `ALLOFME_DEPLOY_USER`
   - `ALLOFME_DEPLOY_SSH_KEY`
4. The deploy user must be able to write to `/var/www/allofme-site`. One simple
   setup is:

   ```sh
   sudo mkdir -p /var/www/allofme-site
   sudo chown -R DEPLOY_USER:DEPLOY_USER /var/www/allofme-site
   sudo find /var/www/allofme-site -type d -exec chmod 755 {} \;
   sudo find /var/www/allofme-site -type f -exec chmod 644 {} \;
   ```

5. Caddy should serve `allofmeapp.com` and `www.allofmeapp.com` from
   `/var/www/allofme-site`.
6. Use these public URLs in App Store Connect:
   - Privacy Policy URL: `https://allofmeapp.com/privacy-policy.html`
   - Support URL: `https://allofmeapp.com/support.html`
   - Marketing URL: `https://allofmeapp.com/`
