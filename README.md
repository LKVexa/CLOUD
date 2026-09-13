# CLOUD JA21 1.5.0 — 24 MB parts

This distribution contains the existing Messenger, Obfuscator, Public Bin and DeleteMe tools, the Windows x64 runtime, JA21 sources and compiler, an Apache 2.0 `LICENSE`, `NOTICE`, application README and instructions sheet.

## Start here

1. Download `00-START-HERE.zip` and all five numbered parts.
2. Extract the small start kit and place all five parts beside `JOIN PARTS.cmd` inside its extracted folder.
3. Run `JOIN PARTS.cmd`. It verifies the sizes and SHA-256 checksums, then reconstructs `CLOUD-JA21-1.5.0-complete.zip`.
4. Extract the completed ZIP using Windows **Extract All**, open `CLOUD-JA21-1.5.0`, and run `START CLOUD.cmd`.

If you already have this whole distribution folder, the kit is already expanded: run the `JOIN PARTS.cmd` beside the parts. Reserve at least 1 GB of free space. Joining does not install or launch the application.

Each part is at most **24,000,000 bytes** (24 MB decimal, below 24 MiB). These are consecutive pieces of one ZIP; an individual part cannot be extracted. `PARTS.json` records order, lengths and checksums. `SHA256SUMS.txt` also lists the part and final-archive checksums. The joiner preserves an existing ZIP with different contents; an identical ZIP is verified and reused. An interrupted join can be run again.

## Compiler and documentation

Inside the assembled application, `COMPILE JA21.cmd` compiles `.ja` and `.jaui` with the bundled runtime, or `.jxd` with the supplied JAXD bootstrap compiler. JAXD and `REBUILD JA21.cmd` require Python 3.10+ installed as `python`. Python is not bundled, and normal application use needs no Python or dependency download. `compiler/README.md` describes commands, outputs and limitations. This is an executable CLOUD application profile, not a full implementation of every JA21 corpus language. Native host/runtime and cryptographic components remain included.

Read `INSTRUCTIONS.txt` for the short instructions sheet, the application's `README.md` for usage and deletion coverage, and `docs/JA21-PROFILE.md` for language scope.

## License and verification

`LICENSE` contains Apache License 2.0; `NOTICE` applies it to new contributions and identifies exclusions. The original supplied CLOUD code was marked UNLICENSED, and the private donor material does not gain a blanket redistribution license from this package. Electron, Chromium, Fluent UI and the supplied JA21 corpora retain their existing terms and notices. The application includes the full `THIRD-PARTY-NOTICES.md` and retained license files.

SHA-256 checking detects mismatched or damaged files; the distribution is not publisher-signed. `DISTRIBUTION-CHECKS.json` records packaging checks. Existing application test evidence is included. The build environment blocked the graphical window test, so live Windows startup, protected-storage persistence, shortcut installation and complete removal handoff remain unverified here.

DeleteMe includes this application's own AppData and the configured channel's shared messages and protected files after confirmation. Its complete scope is shown in the application and documented in the enclosed README.
