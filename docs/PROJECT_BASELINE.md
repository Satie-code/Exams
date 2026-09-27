# EXAMS — PROJECT BASELINE

## 1. Project Overview
- **Project Name:** EXAMS (Electronic eXamination Automation Management System)
- **Role & Scope:** Production-focused exam operations platform managing seating allocation, invigilation duties, bundle logistics, live break monitoring, emergency alerts, and post-exam verification.
- **Repository Root:** `c:\Exams`
- **Current Phase:** Phase 0 (Project Baseline & Development Control)

## 2. Authoritative Technology Stack
- **Frontend:** Flutter (Targeting Android and iOS)
- **Backend:** Node.js (v24.13.0) + Express.js (v4.19.2)
- **Database:** PostgreSQL (v17)
- **ORM:** Prisma (v6.5.0)
- **Authentication:** Email / Staff ID + Password, JWT, Role-based access control (`STUDENT`, `FACULTY`, `ADMIN`)
- **Realtime:** Socket.IO (v4.8.3)
- **QR Scanning:** `mobile_scanner: ^7.2.0`
- **Student Identification:** Manual URN
- **Bundle QR:** Payload contains ONLY `bundle_id`
- **Explicitly Excluded / Removed:** RAG, GPS, Geofencing, Python/FastAPI/SQLAlchemy/Alembic

## 3. Baseline Audit Summary
- **Backend Integrity:** Express server functional with 19 routes across 11 route files. All business logic currently resides inside 5 controllers (`dashboardController.js` is oversized at 694 lines). No dedicated Service or Repository layer exists. Database schema comprises 15 models and 7 enums. No Prisma migration history exists (`prisma db push` used).
- **Frontend Integrity:** Flutter application compiles with 0 errors and 2 lints. Pure `StatefulWidget` / `setState` architecture without external state management. 13 screens in `lib/screens/`, including 1 orphan screen (`seat_details_screen.dart`), 2 completely mocked screens (`student_schedule_screen.dart`, `faculty_colleagues_screen.dart`), and 2 oversized screens (`faculty_dashboard_screen.dart` at 1,350 lines, `faculty_duties_screen.dart` at 1,017 lines).
- **Test Baseline:** Backend unit tests pass (14/14 across 5 test suites). Frontend widget/unit tests fail (7 passed, 8 failed out of 15 tests) due to UI selector mismatches, layout restructuring, and Hero tag conflicts.
- **Security Baseline:** High/Critical findings identified: hardcoded database credentials in `backend/docker-compose.yml`, cleartext HTTP enabled for Android and iOS, wildcard CORS origins, and student URN input not validated against database allocations.
- **Legacy Architecture Status:** Remnants of Python / FastAPI / SQLAlchemy / Alembic are confirmed absent from repository files and Git history.
