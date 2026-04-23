# Methane Mayhem

<!--
<div align="center">
  <a href="https://steviesaurus-dev.itch.io/the-munching-millipede" target="_blank">
    <img src="assets/millipede-thumbnail.png" alt="Methane Mayhem Cover Art" width="400" style="image-rendering: pixelated;" />
  </a>
  <p><em>Click to get on itch.io</em></p>
</div>
-->

## Introduction

Methane Mayhem is a puzzle game written for the Commodore 64.

## Development

Methane Mayhem game is written in Commodore BASIC 2.0 for the Commodore 64.

- developed by Steve
- written in VSCODE using the VS64 extension
- artwork created in Aseprite
- brainstorming partners and design guides: April and Isabella

### Building & Releases

Release packaging uses a hybrid process:

- **Manual for C64** (local build tools required)
- **Automated for Web** (GitHub Actions on release publish)

#### C64 Package (Manual)

Run the packaging script from the project root:

```bash
bash package.sh
```

This script will:

- Build the PRG and inject the version from `config.json` during the build
- Create a d64 disk image using VICE's c1541 tool
- Package both the PRG and d64 files into `methane-mayhem-vX.X.X.zip`

Output files are created in `c64/build/`.

Requirements:

- VICE tools installed (`c1541`)
- VS64 extension tools available locally (as referenced in `package.sh`)

#### Web Package + Pages (Automated)

Workflow: `.github/workflows/release-web.yml`

Trigger:

- Runs when a GitHub Release is **published**

Behavior:

- Reads version from `config.json`
- Replaces `###VERSION###` in:
    - `web/index.html`
    - `web/scripts/index.mjs`
- Creates a web zip named `<repo>-web-vX.X.X.zip`
- Uploads that zip to the same GitHub Release as an asset
- Deploys the same processed web output to GitHub Pages

GitHub setup required:

- Pages source must be set to **GitHub Actions**
- Actions workflow permissions should allow **Read and write permissions**

#### Release Flow

1. Run `bash package.sh` locally and keep the generated C64 zip.
2. Create/publish a GitHub release and upload the C64 zip asset.
3. The release workflow automatically adds the web zip asset and deploys GitHub Pages.

## History

## License

**Code:** Licensed under the [MIT License](LICENSE)

**Assets:** Licensed under [Creative Commons Attribution-NonCommercial-ShareAlike 4.0 International](https://creativecommons.org/licenses/by-nc-sa/4.0/)

Feel free to learn from the code and use it in your own projects. Assets may be shared and adapted under the CC BY-NC-SA 4.0 terms — please provide attribution and share derivative works under the same license.
