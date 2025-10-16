# sabu Development Guidelines

Flutter/Dart savings app with SQLite persistence and Korean localization.

## Commands
- `flutter test` - Run all tests
- `flutter test test/unit_test/specific_test.dart` - Run single test file
- `flutter test --name "test name"` - Run specific test by name
- `flutter analyze` - Run static analysis/lint
- `flutter pub get` - Install dependencies
- `flutter run` - Run app in debug mode

## Code Style & Conventions
- **Imports**: Flutter SDK imports first, then package imports, then relative imports
- **Formatting**: Use single quotes (`'`) for strings, prefer const constructors
- **Types**: Use explicit types for public APIs, leverage type inference for locals
- **Naming**: camelCase for variables/methods, PascalCase for classes, snake_case for files
- **Error Handling**: Use try-catch blocks, return Result types for service methods
- **Widgets**: Prefer StatelessWidget when possible, use const constructors
- **Database**: Use sqflite with proper transaction handling and connection management

## Project Structure
- `lib/` - Main source code (models/, screens/, services/, widgets/, utils/)
- `test/` - All tests (unit_test/, widget_test/, integration_test/)
- Follow flutter_lints rules (prefer_const_constructors, avoid_print, prefer_single_quotes)
