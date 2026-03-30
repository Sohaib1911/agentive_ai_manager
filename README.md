# Agentive AI Project Manager

A cloud-native, reactive mobile application built with Flutter and Firebase designed for task allocation, automated deadline suggestions, and real-time project tracking. This app ditches traditional request-response polling in favor of live Firestore streams to keep Managers and Employees instantly aligned.

## 🚀 Core Features

### 1. Manager Dashboard
* **Agentive Task Allocation:** Create missions and let the built-in logic suggest deadlines based on task priority (High/Medium/Low) and category (Technical/Admin/Creative).
* **Real-Time Analytics:** Monitor team velocity and track the progress of active vs. completed tasks without needing to pull-to-refresh.
* **Global Broadcasts:** Send push alerts and organization-wide notifications with color-coded severity levels (Info, Warning, Critical).

### 2. Employee Dashboard
* **Dynamic Mission List:** Automatically listens to document updates. When a manager assigns a task to your UID, it populates on your device in under a second.
* **State Machine Guardrails:** Updates tasks through a strict lifecycle: `Assigned` -> `In-Progress` -> `Completed`. Prevents accidental state-skipping.
* **Persistent Session:** Firebase Auth handles seamless auto-login on app restart.

---

## 🛠️ Technology Stack

* **Framework:** Flutter (Channel stable, UI built with Material 3)
* **Language:** Dart
* **Backend-as-a-Service:** Firebase (Auth & Cloud Firestore)
* **State Management:** Provider / Riverpod (Reactive stream listening)
* **Architecture:** Cloud-Native NoSQL / Event-Driven

---

## 📦 Project Structure

```text
lib/
├── auth/               # Firebase Auth providers and UI screens
├── logic/              # AgentiveEngine.dart (Deadline math lives here)
├── models/             # Mission and User data models (NoSQL mappers)
├── services/           # FirestoreService.dart & Notification hooks
└── ui/
    ├── employee/       # Task cards, state toggles, and views
    └── manager/        # Creation forms and live metric widgets

Table of Contents
Project Overview

Key Features

Technology Stack

System Architecture

Database / Schema

Project Structure

Prerequisites

Installation & Setup

Running the Application

User Roles

App Dependencies

Submission Contents