# CR Manager

Class Representative ke liye Flutter app — attendance, students list, timetable, aur announcements. Offline SQLite storage (koi internet/login required nahi).

## Features
- **Attendance**: Roll-no wise list, har student default "Present", tap karke "Absent" mark karein. Subject/Teacher/Topic bhi save hota hai.
- **Attendance History**: Har student ki overall % + poori register Excel mein export.
- **Students**: Add/Edit/Delete, ya Excel se bulk import.
- **Timetable**: Day-wise weekly schedule.
- **Announcements**: Post/Edit/Delete.
- **Print**: Attendance sheet ko PDF ke tor par print/share kiya ja sakta hai (Subject, Teacher, Topic, Roll No wise Present/Absent list, signature lines).

## Students Excel Import Format

App import ke liye is format ki Excel file (`.xlsx`) expect karta hai — `sample_students_template.xlsx` dekhein:

| Roll No | Name | Reference No |
|---|---|---|
| 1 | Ali Ahmed | REF-101 |
| 2 | Sara Khan | REF-102 |

**Rules:**
- Pehli row header row honi chahiye. Headers mein "Roll", "Name", "Reference" (ya "Ref") lafz hona chahiye — matching case-insensitive hai, to "roll no", "Roll Number" waghera sab chalenge.
- Column order matter nahi karta — app header ke naam se column dhoondta hai.
- Roll No numeric hona chahiye, koi duplicate na ho.
- Agar aapke doc file mein columns ke naam different hain (jaise sirf "Roll", "Student Name"), to bhi chalega jab tak un mein "roll" aur "name" lafz shamil hon — warna app ka import parser code (`lib/services/excel_service.dart`) mein headers list update karni hogi.

**Suggestion:** Apna asal doc file share karein — agar uske columns is pattern se mukhtalif hue to main `excel_service.dart` ka header-matching logic usi ke mutabiq adjust kar dunga taake import bilkul bina error ke ho.

## Codemagic se Build Karna

1. Yeh poora project (saari files, `codemagic.yaml` samet) apne GitHub repo mein push karein.
2. Codemagic account mein jaa kar "Add application" → apna GitHub repo select karein. Codemagic khud `codemagic.yaml` detect kar lega.
3. Workflow **"CR Manager - Android APK"** select karein aur "Start new build" dabayein.
4. `codemagic.yaml` mein `publishing.email.recipients` wali line mein apna email daal dein taake build complete hone par APK link mil jaye — warna Codemagic dashboard se artifact seedha download ho sakta hai.
5. Build complete hone par `build/app/outputs/flutter-apk/app-release.apk` artifact ke tor par milega.

### Notes
- Yeh config sirf **Android APK** banata hai (iOS shamil nahi).
- Gradle wrapper khud-ba-khud generate ho jata hai build ke doran (`gradle wrapper` step) — is se "gradlew not found" jaisi common Codemagic error nahi aayegi.
- Agar aap apna khud ka signing keystore use karna chahte hain (Play Store ke liye), `android/key.properties` file banayein (`keyAlias`, `keyPassword`, `storeFile`, `storePassword`) — abhi ke liye debug signing se hi APK ban jayega taake side-load/testing ho sake.
- Local testing ke liye: `flutter pub get` phir `flutter run` (Flutter SDK aur Android setup local machine par hona chahiye).
