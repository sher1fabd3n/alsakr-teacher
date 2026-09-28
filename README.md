# الصقر - المعلم

مشروع Flutter مستقل بالكامل (بدون حزمة مشتركة).

## تشغيل
```bash
flutter pub get
flutter run --dart-define=API_BASE_URL=http://172.16.0.114:5286
```

## بناء APK
```bash
flutter build apk --release --dart-define=API_BASE_URL=http://172.16.0.114:5286
```

Package ID: `com.alsakr.school.teacher`