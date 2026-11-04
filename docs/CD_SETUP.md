# One-time CD setup

CI (lint, build, test) needs none of this and works the moment you push.
This document is only for the TestFlight half, which needs your paid Apple
Developer Program membership.

Work through it in order. Each step ends with something you can verify.

---

## 1. Register the app

The bundle identifier in `project.yml` is a placeholder. Pick a real one you
own, e.g. `com.yourname.ciplayground`, then:

```bash
# in project.yml, under targets > CIPlayground > settings > base
PRODUCT_BUNDLE_IDENTIFIER: com.yourname.ciplayground
```

Also update `APP_IDENTIFIER` in `.github/workflows/release.yml`.

Then register it:
- App Store Connect → **Apps** → **+** → New App, using that bundle ID.
- The identifier must also exist in the Developer portal (**Certificates,
  Identifiers & Profiles → Identifiers**). Creating the app usually handles it.

Find your Team ID at <https://developer.apple.com/account> → Membership.

---

## 2. Create an App Store Connect API key

This replaces signing in with your Apple ID. An API key has no 2FA, which is
exactly why CI can use it and a password cannot.

1. App Store Connect → **Users and Access** → **Integrations** → **App Store Connect API**.
2. Generate a key with the **App Manager** role.
3. Download the `.p8`. **You get exactly one download.** Store it in your
   password manager.
4. Note the **Key ID** and the **Issuer ID** shown on that page.

Base64-encode the key so it survives being pasted into a secret:

```bash
base64 -i AuthKey_XXXXXXXXXX.p8 | pbcopy
```

---

## 3. Create the private certificates repo

fastlane match keeps your distribution certificate and provisioning profiles in
a git repo, encrypted. Because this app's repo is public, the certificates repo
**must be a different, private one**.

```bash
gh repo create certificates --private
```

Pick a strong passphrase (this becomes `MATCH_PASSWORD`) and run, from this
project directory:

```bash
export APP_IDENTIFIER=com.yourname.ciplayground
export DEVELOPMENT_TEAM=YOURTEAMID
export MATCH_GIT_URL=https://github.com/<you>/certificates.git

bundle exec fastlane match appstore
```

That generates the distribution certificate and App Store profile, encrypts
them, and pushes them to the private repo. Run it **locally, once** — not on CI.

---

## 4. Give CI read access to the certificates repo

Create a fine-grained personal access token with **read-only Contents** access
to the `certificates` repo only, then encode it the way match expects:

```bash
echo -n "x-access-token:ghp_YOURTOKEN" | base64 | pbcopy
```

---

## 5. Create the GitHub Environment

The release workflow targets an environment named `testflight`. Create it so
the secrets are scoped and you get an approval gate:

- Repo → **Settings** → **Environments** → **New environment** → `testflight`.
- Optionally add yourself under **Required reviewers**, so every deploy waits
  for a human click.

---

## 6. Add the secrets

Add these to the **`testflight` environment** (not repo-wide):

| Secret | Value |
|---|---|
| `APP_STORE_CONNECT_KEY_ID` | Key ID from step 2 |
| `APP_STORE_CONNECT_ISSUER_ID` | Issuer ID from step 2 |
| `APP_STORE_CONNECT_KEY_P8` | base64 of the `.p8` from step 2 |
| `MATCH_GIT_URL` | `https://github.com/<you>/certificates.git` |
| `MATCH_PASSWORD` | The match passphrase from step 3 |
| `MATCH_GIT_BASIC_AUTHORIZATION` | base64 string from step 4 |
| `DEVELOPMENT_TEAM` | Your 10-character Team ID |

With `gh`:

```bash
gh secret set APP_STORE_CONNECT_KEY_ID --env testflight
gh secret set APP_STORE_CONNECT_ISSUER_ID --env testflight
gh secret set APP_STORE_CONNECT_KEY_P8 --env testflight < key.p8.base64
gh secret set MATCH_GIT_URL --env testflight
gh secret set MATCH_PASSWORD --env testflight
gh secret set MATCH_GIT_BASIC_AUTHORIZATION --env testflight
gh secret set DEVELOPMENT_TEAM --env testflight
```

---

## 7. Ship

```bash
git tag v1.0.0
git push origin v1.0.0
```

Watch it: `gh run watch`.

---

## Debugging notes

**`No signing certificate "iOS Distribution" found`** — `match` didn't install
anything. Check `MATCH_PASSWORD` and that `MATCH_GIT_BASIC_AUTHORIZATION` is
base64 of `x-access-token:<token>` with **no trailing newline** (`echo -n`).

**`Could not find profile`** — the profile name in the export options didn't
match what `match` installed. The lane reads it from the
`sigh_<bundleid>_appstore_profile-name` variable that `sync_code_signing` sets;
if the bundle ID in `project.yml` and `APP_IDENTIFIER` disagree, this breaks.

**`Invalid Pre-Release Train`** — the version in `project.yml`
(`MARKETING_VERSION`) already shipped. Bump it.

**`The provided entity includes an attribute with a value that has already been used`** —
that build number is taken. The lane derives it from App Store Connect, so this
usually means a build is still processing; wait and re-run.

**Keychain errors on CI** — `setup_ci` must run before `match`. It's in
`before_all`, guarded by `is_ci`.

## Running the deploy without a tag

To test the pipeline without creating version history, use the manual trigger:

```bash
gh workflow run release.yml -f changelog="testing the pipeline"
```
