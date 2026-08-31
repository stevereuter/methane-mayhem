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
- written in VSCODE using the VS64 extension (see [VS64 setup note](#vs64-extension-setup) below — Marketplace version is outdated)
- artwork created in Aseprite
- brainstorming partners and design guides: April and Isabella

### Building & Releases

Release packaging uses a hybrid process:

- **Manual for C64** (local build tools required)
- **Automated for Web** (GitHub Actions on release publish)

#### C64 Build (Versioned, Non-Mutating)

Default C64 builds now run through `c64/build-versioned.sh`.

What this does:

- Reads the version from `config.json`
- Replaces `{version}` placeholders into generated files under `c64/build/generated/`
- Compiles from generated sources so files in `c64/src/` are never modified

##### LET-Join Step

After version/include substitution, `c64/build-versioned.sh` runs `c64/tools/join_let_lines.py` against the generated `.bas` files.

Commodore BASIC 2.0 line/statement limits reward fewer, denser lines, but that's harder to read in source. So `c64/src/` lists consecutive `LET` assignments vertically, one per line, for readability. This step:

- Finds consecutive `LET` lines and joins them into packed multi-statement lines (`:`-separated), capped at a max line length (76 chars, passed as an argument in `build-versioned.sh`)
- Strips the redundant `LET` keyword when combining, since BASIC doesn't require it
- Reduces both source line count and tokenized program size, which matters for C64 BASIC's line/statement limits

This only affects the generated build output — `c64/src/` files keep their original, more readable one-variable-per-line form.

Current placeholders are in:

- `c64/src/splash.bas`
- `c64/src/characters.bas`

The default VS Code build task in `c64/.vscode/tasks.json` is set to run this wrapper.

#### C64 Package (Manual)

Run the packaging script from the project root:

```bash
bash package.sh
```

This script will:

- Run `c64/build-versioned.sh` to build a versioned PRG from generated inputs
- Create a d64 disk image using VICE's c1541 tool
- Package both the PRG and d64 files into `methane-mayhem-vX.X.X.zip`

##### Character/Sprite Asset Injection

Custom characters and sprites are authored in Aseprite and exported as JSON (see the `assets/` folder). `config.json`'s `binaries` array points at those JSON exports and describes how to turn each one into a raw PRG:

- `c64/tools/add_config_binaries.py` reads each entry's `path`, `type` (`characters` or `sprites`), and `loadAddress`, converts the Aseprite JSON into a raw binary at that load address, and adds it to the built D64 image under the entry's `discName` (e.g. `chars`, `sprites`)
- These PRGs are separate from the main program PRG — they're loaded from disk at runtime rather than compiled into `Methane Mayhem.prg`

At runtime, `c64/src/fileLoader.bas` performs the multi-file load: it steps through an `on x goto` state machine that issues sequential `load "chars", 8, 1` / `load "sprites", 8, 1` calls (each `load` reloads BASIC and resumes at the next state) until all configured binaries are loaded from disk.

Output files are created in `c64/build/`.

Requirements:

- VICE tools installed (`c1541`)
- VS64 extension tools available locally (resolved by `c64/build-versioned.sh`)

##### VS64 Extension Setup

The VS64 extension on the VS Code Marketplace hasn't been updated in over a year and is 6 versions behind. Install `v2.7.4` manually instead:

1. Download the `v2.7.4` VSIX release from the [VS64 GitHub releases page](https://github.com/rolandshacks/vs64/releases).
2. In VS Code, open the Extensions view, click the `...` menu, and choose **Install from VSIX...**
3. Select the downloaded `.vsix` file.

`c64/build-versioned.sh` resolves the VS64 tools locally once the extension is installed, falling back to system `python3` if needed.

#### Web Package + Pages (Automated)

Workflow: `.github/workflows/release-web.yml`

Trigger:

- Runs when a GitHub Release is **published**

Behavior:

- Reads version from `config.json`
- Replaces `{version}` in any matching file inside copied `dist-web/` content
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

#### Porting This To Template Repo

When copying this workflow to a template project, copy/update these pieces together:

1. `c64/build-versioned.sh`
2. `c64/.vscode/tasks.json` default build task
3. `package.sh` (call into `c64/build-versioned.sh`)
4. `{version}` placeholders in any BASIC and web files
5. `.github/workflows/release-web.yml` placeholder replacement step

Quick verification after porting:

1. Run C64 default build task and confirm PRG is produced in `c64/build/`.
2. Confirm version text appears in emulator output.
3. Run `bash package.sh` and confirm zip + d64 output.

## History

## License

Code: Licensed under the [MIT License](LICENSE)

Assets: Licensed under [Creative Commons Attribution-NonCommercial-ShareAlike 4.0 International](assets/LICENSE)

Feel free to learn from the code and use it in your own projects. Assets (images, sprites, audio, etc.) and data generated from them may be shared and adapted under the CC BY-NC-SA 4.0 terms — please provide attribution and distribute derivative works under the same license.
