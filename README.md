# Pokémon Flutter App

This repository contains a Flutter-based Pokémon app, designed as a starting point for building Flutter applications.  It leverages several popular Flutter packages to provide features like HTTP requests, state management, animations, caching, and custom fonts.

## Features

*   **API Integration:**  Uses the `http` package for network requests.
*   **State Management:** Employs the `provider` package for managing application state.
*   **Animations:**  Includes animations using `lottie`, `flutter_animate`, and `confetti`.
*   **Image Caching:**  Utilizes `cached_network_image` for efficient image loading and caching.
*   **Custom Fonts:**  Supports custom fonts via `google_fonts`.
*   **UI Enhancements:**  Adds shimmer effects (loading placeholders) with the `shimmer` package.

## Setup Instructions

### Prerequisites

Ensure the following are installed:

*   **Flutter SDK (version 3.7.0 or higher):** [Install Flutter](https://docs.flutter.dev/get-started/install)
*   **Android Studio or Xcode:** For Android/iOS development, respectively.
*   **Dart SDK:**  Included with the Flutter SDK.
*   **Git:**  For cloning the repository.

### Installation Steps

1.  **Clone the Repository:**

    ```bash
    git clone <repository-url>
    cd pokemon_flutter
    ```

2.  **Install Dependencies:**

    ```bash
    flutter pub get
    ```

3.  **Run the App:**

    Connect a device or start an emulator/simulator, then:

    ```bash
    flutter run
    ```

4.  **Build for Release:**

    *   **Android:**
        ```bash
        flutter build apk
        ```
    *   **iOS:**
        ```bash
        flutter build ios
        ```

## Project Structure

*   **`pubspec.yaml`:**  Contains dependencies, asset configurations, and environment settings. Key dependencies include:
    *   `http`:  HTTP requests.
    *   `provider`: State management.
    *   `cached_network_image`: Image caching.
    *   `lottie`, `flutter_animate`, `confetti`: Animations.
    *   `google_fonts`: Custom fonts.
    *   `shimmer`: Loading placeholders.

*   **Assets:**  The `assets/Pokemon/Pokemon_Animation.json` file contains a Lottie animation for visual effects.

*   **Gradle Configuration:** Android-specific settings are in `android/build.gradle.kts` and `android/app/build.gradle.kts`. These files include:
    *   Minimum and target SDK versions.
    *   Kotlin and Java compatibility.
    *   Build types (debug, release).

## What This App Does

This project is a template for a Pokémon-themed Flutter app. It can be extended to include:

*   Displaying Pokémon data from an API (e.g., PokéAPI).
*   Animations and celebratory effects (Lottie, Confetti).
*   Caching images for offline access.
*   Dynamic font styling (Google Fonts).

Currently, it's a basic setup with foundational tools and configurations, providing a starting point for creating a visually appealing and performant Flutter application.

## Additional Notes

*   **Documentation:** Refer to the [official Flutter documentation](https://docs.flutter.dev/) for more help.

*   **Customizations:**

    *   Update the `applicationId` in the Gradle file with your own unique identifier.
    *   Add assets or dependencies as needed.

---

This repository provides a flexible foundation for building a feature-rich Pokémon app or any other Flutter-based application!
