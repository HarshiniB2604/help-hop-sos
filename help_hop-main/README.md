# 📱 HelpHop — Secure Mesh-Based Disaster Response App

HelpHop is an **offline-first disaster response application** built using Flutter.
It enables **victims** to send SOS alerts and **rescuers** to view/respond using a secure mesh network (Bluetooth + Wi-Fi Direct).

This repo contains the **UI + basic flows** for:

* Victim App
* Rescuer App
* Role selection
* Onboarding
* SOS screen
* Direct messaging
* Rescuer dashboard
* Pre-disaster alerts

---

## 🚀 Features (Current Version)

### **Victim Interface**

* SOS button with emergency type selection
* Offline message relay placeholder
* Direct chat (demo)
* Alert screen for pre-disaster announcements
* Full 3-step onboarding
* Profile & settings

### **Rescuer Interface**

* PIN-protected login
* List of SOS requests
* Accept/Reject logic
* Direction guidance (demo)
* Mark as Rescued

### **General**

* Role selection (Victim / Rescuer)
* Local storage using SharedPreferences
* Clean Material 3 UI

---

## 🔧 Tech Stack

### **Frontend (Flutter)**

* Flutter + Dart
* SharedPreferences
* Material 3
* intl package
* State management: Stateful widgets (simple & clean)

### **Future Integrations**

* Bluetooth mesh
* Wi-Fi Direct relay
* End-to-end encryption
* Node.js backend + Dashboard
* Firebase FCM for pre-disaster alerts

---

## 🧪 Running the App

```bash
flutter pub get
flutter run -d chrome
```

or on Android:

```bash
flutter run
```

---

## 📂 Project Structure (Important Files)

```
lib/
 ├── main.dart
 ├── screens/
 ├── onboarding/
 ├── rescuer/
 ├── chat/
 ├── sos/
```

(Currently all merged into main.dart — will be modularized soon.)

---

## 👨‍💻 Contributors

* Huda Fatimah
* Manyashree S
* Devisri Harshini Baramal
* G. Roweena Siphora

DTL — Disaster Response System
Secure Mesh-Based Communication App

---

## ❤️ Future Work

* Implement actual offline mesh (BLE + Wi-Fi Direct)
* Build backend for packet ingestion
* Create rescuer dashboard (React + Supabase)
* Add encryption module
* Add local chat groups
* Add real distance + compass
* Add upload of SOS packets to cloud database
* Integrate Firebase pre-disaster notifications