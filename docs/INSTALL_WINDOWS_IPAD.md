# Install NightPDF On iPad From Windows

You cannot copy an arbitrary `.ipa` to an iPad and open it like a Windows `.exe`. iPadOS requires a valid signature and a provisioning profile that authorizes the device or distribution channel.

With a free Apple Account, personal signing normally lasts about 7 days. After that, refresh or reinstall the app.

## Build Artifact

1. Push the project to GitHub.
2. Open the repository on GitHub.
3. Go to **Actions**.
4. Run **Build IPA** manually.
5. Download the `NightPDF-build` artifact.

The artifact may include:

- `NightPDF.ipa`
- `NightPDF.xcarchive.zip`
- `build-info.txt`
- `checksums.txt`

The `.ipa` produced by CI is unsigned unless you later add a paid signing setup with GitHub Secrets.

## Option A: AltStore Classic

Requirements:

- Windows 10 or 11.
- AltServer for Windows.
- iTunes and iCloud components required by AltStore.
- A free Apple Account.
- iPad connected for the initial setup.

Steps:

1. Install AltServer on Windows.
2. Install AltStore Classic on the iPad through AltServer.
3. Download `NightPDF.ipa` from GitHub Actions.
4. Open the `.ipa` in AltStore Classic.
5. Let AltStore sign and install it with your Apple Account.
6. Refresh before the 7-day free-signing period expires.

AltStore Classic is more convenient if you want recurring refreshes over Wi-Fi.

## Option B: Sideloadly

Requirements:

- Windows.
- Sideloadly.
- Apple device support through iTunes/iCloud components.
- A free Apple Account.
- iPad connected or visible to the PC.

Steps:

1. Download `NightPDF.ipa` from GitHub Actions.
2. Open Sideloadly.
3. Select the iPad.
4. Select `NightPDF.ipa`.
5. Enter the Apple Account used for signing.
6. Install the app.
7. Repeat when the free signature expires.

Sideloadly is usually the most direct path for one personal app.

## Paid Apple Developer Program

A paid account is only needed for TestFlight, App Store, stable Ad Hoc distribution, longer-lived signing assets, or automated signing. The free Windows path above does not use TestFlight.

