# my_money_manager

A new Flutter project.

## Android build: "NDK Clang could not be found"

If you see **Android NDK Clang could not be found** when running `flutter run` on Android:

1. **Install Android NDK** (required for native plugins like sqflite):
   - Open **Android Studio** → **Settings** (or **Preferences** on macOS) → **Languages & Frameworks** → **Android SDK** → **SDK Tools** tab.
   - Enable **NDK (Side by side)** and **CMake**.
   - Click **Apply** and wait for the install to finish.

2. **Clean and run again**:
   ```bash
   flutter clean
   flutter run
   ```

If NDK is already installed but the error persists, ensure **Android SDK Command-line Tools** are installed (same SDK Tools screen) and that `ANDROID_HOME` (or `ANDROID_SDK_ROOT`) points to your SDK directory.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
