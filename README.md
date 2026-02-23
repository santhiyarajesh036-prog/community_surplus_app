# Community Surplus Distribution Hub 📦

A cross-platform Flutter application that connects donors and receivers to share surplus items efficiently and reduce waste in the community.

---

## 📱 Overview

Community Surplus is a mobile platform where users can donate unused items and request items they need.
The app promotes reuse culture and helps economically weaker individuals access essential resources.

---

## 🚀 Features

### User Management

* Secure authentication using Firebase Auth
* Profile creation and editing
* Online / offline user status

### Donation System

* Add item with image and description
* View available donations
* Manage your posted donations

### Request System

* Request items from donors
* Donor approval / rejection
* Request tracking

### Chat & Notifications

* Real-time chat between donor and receiver
* Push notifications using Firebase Cloud Messaging
* Request status alerts

### Smart Updates

* Live item availability updates (Firestore)
* Notification system for activity tracking

---

## 🛠️ Tech Stack

| Technology               | Purpose                |
| ------------------------ | ---------------------- |
| Flutter (Dart)           | Mobile App Development |
| Firebase Authentication  | User Login             |
| Cloud Firestore          | Database               |
| Firebase Storage         | Image Upload           |
| Firebase Cloud Messaging | Push Notifications     |
| Cloud Functions          | Background Events      |

---

## 📂 Project Structure

```
lib/
 ├── models/
 ├── screens/
 ├── services/
 ├── data/
 └── main.dart
```

---

## ⚙️ Setup Instructions

1. Clone the repository

```
git clone https://github.com/santhiyarajesh036-prog/community_surplus_app.git
```

2. Install dependencies

```
flutter pub get
```

3. Add your Firebase configuration
   Place your own:

```
android/app/google-services.json
```

4. Run the app

```
flutter run
```

---

## 🎯 Objective

To minimize resource wastage and help communities by enabling easy sharing of surplus goods through a simple mobile platform.

---

## 👩‍💻 Developed By

Santhiya R
