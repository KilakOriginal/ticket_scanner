# Ticket Scanner

A Flutter-based mobile application for scanning and managing tickets with the power of Supabase for backend services and data synchronisation.

## Features

- **Ticket Scanning**: Utilises mobile device cameras to scan tickets.
- **Supabase Integration**: Securely syncs scanned data with a Supabase backend.
- **Localisation Support**: Multi-language support for a global audience.
- **Periodic Synchronisation**: Ensures offline data is synchronised periodically.
- **Customisable Themes**: Leverages Material Design for a modern user experience.

## Installation

1. **Clone the repository**:
   ```bash
   git clone https://github.com/KilakOriginal/ticket_scanner.git
   cd ticket_scanner
   ```

2. **Install Dependencies**:
   ```bash
   flutter pub get
   ```

3. **Run the App**:
   ```bash
   flutter run --release
   ```

## Usage

1. Launch the application on your device or emulator.
2. Use your device's camera to scan tickets via the app.
3. The app will sync scanned data with the Supabase backend.
4. Access localised content by setting your preferred language in the app.

## Dependencies

The following main dependencies are used in this project:

- [`mobile_scanner`](https://pub.dev/packages/mobile_scanner): For scanning QR codes or barcodes.
- [`supabase_flutter`](https://pub.dev/packages/supabase_flutter): For backend integration and data synchronisation.
- [`flutter_localization`](https://pub.dev/packages/flutter_localization): For localisation and multi-language support.
- [`permission_handler`](https://pub.dev/packages/permission_handler): For managing runtime permissions.
- [`shared_preferences`](https://pub.dev/packages/shared_preferences): For storing user preferences locally.

## Project Structure

- **`lib/main.dart`**: Entry point of the application.
- **Localisation**: Uses `flutter_localization` with pre-configured locales.
- **Backend**: Integration with Supabase for storing and syncing ticket data.

## Contributing

Contributions are welcome! Please follow these steps:

1. Fork the repository.
2. Create a new branch:
   ```bash
   git checkout -b feature-name
   ```
3. Commit your changes and push the branch:
   ```bash
   git commit -m "Description of changes"
   git push origin feature-name
   ```
4. Open a pull request.

## License

This project is licensed under the MIT License. See the `LICENSE` file for details.
