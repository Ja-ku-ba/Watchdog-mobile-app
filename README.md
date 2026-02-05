# Watchdog
## Aplikacja do zarządzania systemem monitoringu z detekcją twarzy, oparta o urządzenie monitorujące na RaspbberyPi 5

Aplikacja składa się z 3 modułów
- https://github.com/Ja-ku-ba/Watchdog-server
- https://github.com/Ja-ku-ba/Watchdog-mobile-app
- https://github.com/Ja-ku-ba/Watchdog-Raspberrypi

Przed uruchomieniem upewnij się, że masz zainstalowane:
- **Flutter SDK** (zalecana wersja: stable)
- **Dart SDK** (instaluje się razem z Flutterem)
- **Android Studio / VS Code** (z wtyczką Flutter & Dart)
- Emulator Androida lub urządzenie fizyczne, minimalne wymagane SDK to 34

Sprawdź instalację:
```bash
flutter doctor
```

git clone https://github.com/Ja-ku-ba/Watchdog-mobile-app
cd nazwa-projektu

Skopiuj plik env i nazwij go .env
Dostosuj zmienne środowiskowe w pliku .env

Pobierz zależności
```bash
flutter pub get
```

Uruchom projekt
```bash
flutter run
```

Wybuduj aplikację
```bash
flutter build apk
```