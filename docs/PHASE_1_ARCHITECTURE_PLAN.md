# EXAMS — PHASE 1 ARCHITECTURE PLAN
**Subsystem:** System Architecture & Hardening Roadmap  
**Status:** Canonical Reference for Phase 1 Execution  
**Target:** Production Baseline Without Changing Product Behavior  

---

## 1. Executive Context & Objectives

Phase 0 established that the EXAMS project is a functional early alpha prototype.
The objective of Phase 1 is:
> **Harden the existing codebase without changing product behavior.**

The frozen technology stack:
- **Backend:** Node.js, Express.js, Prisma ORM, PostgreSQL, Socket.IO, JWT Auth, Helmet, Express-Rate-Limit.
- **Frontend:** Flutter (Dart), Android, iOS.
- **Strictly Excluded:** No Python, no FastAPI, no Alembic, no RAG, no GPS, no Geofencing, no MongoDB, no Flutter state management overhaul.

---

## 2. Current Architecture vs. Target Architecture

### Backend: Current State
```
Client Request (HTTP / Socket.IO)
      │
      ▼
Express Route (e.g., routes/bundleRoutes.js)
      │
      ▼
Controller (e.g., controllers/dashboardController.js)
  ┌─────────────────────────────────────────────────────────────┐
  │ - Parses HTTP parameters                                   │
  │ - Performs direct Prisma queries & transactions             │
  │ - Contains business rules (e.g., washroom violation timer)  │
  │ - Emits Socket.IO realtime events                           │
  │ - Formats and returns HTTP response                         │
  └─────────────────────────────────────────────────────────────┘
      │
      ▼
Prisma ORM Client
      │
      ▼
PostgreSQL Database
```
**Deficiencies in Current State:**
1. **Monolithic Controllers:** `dashboardController.js` (694 lines) handles bundle scanning, attendance, supplies, SOS, washroom tracking, post-exam reports, and dashboard aggregation.
2. **Coupled Socket.IO:** Direct `getIO().to(...).emit(...)` in controllers causes console errors during testing and couples transport to domain operations.
3. **No Service Boundaries:** Impossible to unit test business logic without mocking the Express request/response pipeline and Prisma client simultaneously.

### Backend: Target State (Phase 1)
```
Client Request (HTTP / Socket.IO)
      │
      ▼
Express Route (e.g., routes/bundleRoutes.js)
      │
      ▼
Controller (e.g., controllers/dashboardController.js)
  ┌─────────────────────────────────────────────────────────────┐
  │ - Extracts and validates input format                       │
  │ - Extracts user identity from req.user                      │
  │ - Delegates to domain service                               │
  │ - Formats HTTP response status and body                     │
  │ - Forwards unexpected errors to next(err)                   │
  └─────────────────────────────────────────────────────────────┘
      │
      ▼
Domain Service Layer (e.g., services/bundleService.js, services/washroomService.js)
  ┌─────────────────────────────────────────────────────────────┐
  │ - Enforces business rules & invariants                      │
  │ - Coordinates Prisma queries & transactions                 │
  │ - Calculates domain metrics (e.g., washroom state, duration)│
  │ - Safely emits realtime events via notification helper      │
  └─────────────────────────────────────────────────────────────┘
      │
      ▼
Data Access (Prisma Client: config/prisma.js)
      │
      ▼
PostgreSQL Database
```

---

### Flutter: Current State vs. Target State

### Current State
```
Screen Widget (e.g., faculty_dashboard_screen.dart: 1,350 lines)
  ├── Page scaffolding & floating action buttons
  ├── Countdown timer calculations & ticker loop
  ├── Modal bottom sheet builders (Supplies, SOS, Washroom)
  ├── 12+ embedded Private Widgets (_ActionTile, _WashroomBreakCard, _ActivityPanel, etc.)
  ├── Direct navigation to QRScanner and PostExamReport
  └── Inline state management (ValueNotifier, setState)
```
**Deficiencies in Current State:**
1. Excessive file length makes changes risky and difficult to review.
2. Multiple `FloatingActionButton` widgets inside the same route trigger Hero tag collisions.
3. Layout components cannot be reused across duties and settings screens.

### Target State (Phase 1)
```
Screen Widget (lib/screens/faculty_dashboard_screen.dart)
  │ (Maintains lifecycle, state, ticker, and API calls)
  │
  ├── lib/widgets/faculty/
  │     ├── faculty_dashboard_header.dart   (Course code, room, countdown)
  │     ├── faculty_action_grid.dart        (Scan materials, scan students, request supplies)
  │     ├── faculty_washroom_section.dart   (Live washroom break cards and timers)
  │     ├── faculty_activity_panel.dart     (Recent activity feed)
  │     └── faculty_sos_sheet.dart          (SOS modal selector)
  │
  └── lib/widgets/duties/
        ├── duty_card.dart                  (Status badge, metadata, swap button)
        ├── duty_top_tabs.dart              (Upcoming duties vs. history)
        └── duty_swap_sheet.dart            (Faculty peer swap selector)
```

---

## 3. Migration Strategy & Execution Boundaries

### Principle: Zero Behavioral Regressions
1. **Preserve Exact API Contracts:**
   - Routes, parameters, HTTP status codes, JSON payload keys, and error responses remain 100% byte/field compatible.
2. **Controller Facades:**
   - `dashboardController.js` retains all 8 exported functions (`scanBundle`, `markAttendance`, `requestSupplies`, `requestSOS`, `submitReport`, `startWashroomTimer`, `endWashroomTimer`, `getActivity`).
   - Controllers delegate to domain services in `backend/services/`.
3. **Flutter Visual & Behavioral Preservation:**
   - Colors (`#4560BD`, `#25B468`, `#E92822`, `#F7F9FE`), typography, paddings, shadows, and animations remain identical.
   - Decomposition into `lib/widgets/faculty/` and `lib/widgets/duties/` strictly isolates presentation widgets while keeping screen controllers intact.
4. **Hero Tag Collision Remediation:**
   - Explicitly provide `heroTag: null` or unique tags to all `FloatingActionButton`s in `faculty_dashboard_screen.dart`.
5. **Prisma Version Consolidation:**
   - Reconcile root `package.json` with `backend/package.json` to prevent CLI/client version collisions.

---

## 4. Modules Requiring Refactoring

| Module | Location | Current State | Target Phase 1 State |
|---|---|---|---|
| **Dashboard Controller** | `backend/controllers/dashboardController.js` | 694 lines; mixed DB/logic/sockets | Slim controller delegating to `backend/services/` |
| **Domain Services** | `backend/services/` | Does not exist | Create `bundleService.js`, `washroomService.js`, `sosService.js`, `reportService.js`, `attendanceService.js`, `activityService.js` |
| **Faculty Dashboard** | `frontend/.../faculty_dashboard_screen.dart` | 1,350 lines; multiple FABs | Modular screen importing widgets from `lib/widgets/faculty/` |
| **Faculty Duties** | `frontend/.../faculty_duties_screen.dart` | 1,017 lines; embedded cards | Modular screen importing widgets from `lib/widgets/duties/` |
| **Package Config** | `package.json` vs `backend/package.json` | Prisma 7.5 root vs 6.5 backend | Standardize on Prisma 6.5 across workspace |
| **Environment Config** | `backend/.env.example` & `docker-compose.yml` | Hardcoded password in compose | Parameterized environment variables |

---

## 5. Identified Risks & Mitigations

1. **Risk:** Controller refactoring breaks existing Jest unit test suite.
   - **Mitigation:** Unit tests mock `../config/prisma`. Services will utilize `config/prisma.js` so transaction semantics and mocking remain fully intact.
2. **Risk:** Widget extraction alters widget tree depth and breaks widget finder tests.
   - **Mitigation:** Use `StatelessWidget` extractions without injecting intermediate routing or layout containers.
3. **Risk:** Database drift or destructive migrations.
   - **Mitigation:** No `prisma migrate reset`, no `db push --force-reset`. Use safe migration baselining.

---

## 6. Expected Behavioral Invariants

1. All 14 backend Jest tests continue to pass without changing test assertions.
2. All 15 Flutter tests pass after resolving Hero tag collisions, scroll visibility, and stale test dates.
3. Express HTTP endpoints return identical JSON responses for valid and invalid inputs.
4. Socket.IO `ACTIVITY_LOGGED` and `NEW_SOS` events are broadcast to `admin_room`.
5. Database rows in PostgreSQL are never truncated or dropped during development.
