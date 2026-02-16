# SheRise Application Flow & Architecture (Deep Dive)

This document outlines the complete technical flow of the SheRise application, from initialization to core services.

## 1. Application Entry Point (`main.dart`)

The application starts execution in `main()`.
- **Parallel Initialization**: To optimize startup time, the following are triggered simultaneously:
  - `dotenv.load()`: Loads environment variables.
  - `EasyLocalization.ensureInitialized()`: Prepares the localization engine.
  - `HomeWidget.registerInteractivityCallback()`: Registers the callback for Android Home Screen widgets (for immediate SOS trigger).
  - `SharedPreferences.getInstance()`: Preloads the storage.

- **Routing Logic**:
  - The `MyApp` widget checks the `onboarding_complete` boolean from SharedPreferences.
  - **Dependency Injection**: It injects `AuthCubit` (using `LocalAuthRepo`) into the widget tree via `BlocProvider`.

---

## 2. State Management System (`AuthCubit`)

The app uses the **BLoC (Business Logic Component)** pattern for managing user sessions.
**File:** `lib/features/auth/presentation/cubits/auth_cubit.dart`

- **States**:
  - `AuthInitial`: App just started.
  - `AuthLoading`: Waiting for async operations.
  - `Authenticated`: User is logged in (contains `AppUser` object).
  - `Unauthenticated`: User needs to log in.

- **Logic**:
  - `checkAuth()`: Calls `AuthRepo.getCurrentUser()`. If data exists in SharedPreferences, it emits `Authenticated`.
  - `saveUserDetails()`: Writes user data to local storage and updates the state.
  - `logout()`: Clears all SharedPreferences data and deletes the local profile picture file.

---

## 3. Data Persistence Layer (`LocalAuthRepo`)

Currently, the app uses a **Local-Only Authentication** mechanism.
**File:** `lib/features/auth/data/local_auth_repo.dart`

- **Storage**: Uses `SharedPreferences` to store:
  - `user_name`, `user_surname`
  - `user_dob` (ISO-8601 string)
  - `user_profile_pic` (Path to file)
  - `setup_complete` (Boolean)
  - `emergency_contact` (String)

- **Verification**: Since it's local, there is no actual backend server validation in this version. "Logging in" simply means checking if valid user data exists in SharedPreferences.

---

## 4. Key Feature Implementations

### A. Emergency SOS Service
**File:** `lib/features/safety/safety_service.dart`

This singleton service handles life-critical functions.
1.  **Siren**: Uses `audioplayers` to play a looped MP3 asset (`siren.mp3`) from the root bundle.
2.  **SMS Logic (`_sendEmergencySMS`)**:
    - Checks `Telephony` permissions.
    - Fetches high-accuracy location via `Geolocator`.
    - Generates a Google Maps link.
    - Fetches contacts from SharedPreferences.
    - Sends background SMS using `Telephony.instance.sendSms`.
3.  **Live Location**:
    - Starts a `Timer.periodic` (10 minutes).
    - Re-fetches location and sends an "Update" SMS to trusted contacts repeatedly for 1 hour.

### B. Localization Engine
**File:** `lib/core/services/localization_service.dart`

Handles dynamic language support (Online & Offline).
- **Online**: Downloads JSON language files (e.g., `hi.json`) from a remote GitHub repository to a temporary cache directory.
- **Offline**: `makePermanent()` copies the cached JSON to the application's document directory.
- **Deep Integration**: `EasyLocalization` library is configured in `main.dart` to look for these files, allowing the app to switch languages instantly without app updates.

---

## 5. UI & Navigation Flow

### A. Onboarding (`LandingPage` -> `FeatureShowcase`)
- **Animations**: Uses `AnimationController` for fade/scale effects on the logo.
- **Persistence**: Upon clicking "Get Started", it sets `onboarding_complete = true`.

### B. Authentication (`AuthFlowWrapper`)
- This widget acts as a traffic controller.
- It listens to `AuthCubit` stream.
- **Routing**:
  - `Unauthenticated` -> `DiscoveryPage` / `AuthPage`.
  - `Authenticated` (but `!user.isSetupComplete`) -> `SetupPage`.
  - `Authenticated` (and `isSetupComplete`) -> `MainPage`.

### C. Main Hub (`MainPage`)
- **Structure**: `Scaffold` with a `PageView` (disabled scrolling) and a custom transparent `BottomNavigationBar`.
- **KeepAlive**: Sub-pages like `HomePage` and `VideosPage` use `AutomaticKeepAliveClientMixin` to prevent reloading widgets when switching tabs.
