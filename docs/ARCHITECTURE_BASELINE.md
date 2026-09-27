# EXAMS — ARCHITECTURE BASELINE

## 1. Backend Architecture

### Current Layering Pattern
The backend does **NOT** follow a clean multi-tiered architecture (Route → Controller → Service → Repository → Database).

Instead, the actual architecture is:
```
HTTP Request / Socket Event
   ↓
Route Handler (Express Router)
   ↓
Controller (Contains Validation + Business Logic + Direct Prisma Access + Socket Emits)
   ↓
Prisma Client (`@prisma/client`)
   ↓
PostgreSQL Database
```

### Architectural Characteristics
1. **No Service Layer:** Business rules (such as swap validations, status transitions, duration metrics, report logic) are written directly inside the controller methods.
2. **No Repository Layer:** Direct `prisma.<model>.<operation>()` calls are executed directly in controller files.
3. **Oversized Controllers:**
   - `backend/controllers/dashboardController.js` (694 lines, 18.2 KB): Implements 8 separate endpoints (bundles, attendance, supplies, SOS, reports, washroom start/end, activity feed) alongside washroom duration logic and Socket.io broadcasts.
   - `backend/controllers/facultyController.js` (320 lines, 7.9 KB): Implements duties listing, swap option evaluation, swap creation, and transaction handling.
4. **Realtime Coupling:** Socket.IO is initialized in `server.js` and imported into controllers via `const { getIO } = require("../config/socket")`. Controllers execute `getIO().to("admin_room").emit(...)` directly inside database transaction handlers, wrapped in try/catch blocks that print to `console.error` when Socket.IO is uninitialized (e.g. during test runs).
5. **Database Interaction:** Transactions are executed using `prisma.$transaction(async (tx) => { ... })` directly inside controller functions.

---

## 2. Frontend Architecture (Flutter)

### Application Entry & State Management
- **Entry Point:** `frontend/exams/lib/main.dart` (`ExamsApp` → `_AuthGate`).
- **State Management:** Pure `StatefulWidget` / `setState` and `ValueNotifier`. No external state management framework (no Provider, Riverpod, Bloc, GetX, or Redux).
- **Session Handling:** `_AuthGate` inspects `flutter_secure_storage` for `access_token` and `user_role`. If missing, routes to `LoginScreen`. When present, directs to `FindMySeatScreen` (STUDENT), `FacultyDutiesScreen` (FACULTY), or `AdminDashboardScreen` (ADMIN).
- **Navigation Structure:** Custom imperative navigation. Bottom navigation bars switch screens by calling `Navigator.pushReplacement` with a zero-duration `PageRouteBuilder`, unmounting and recreating screen widgets on each tab switch.
- **Service Layer:** `AuthApiService`, `StudentApiService`, `FacultyApiService`, and `AdminApiService` encapsulate raw HTTP client calls using `package:http`.
- **Realtime Layer:** Realtime Socket.IO is restricted exclusively to `AdminDashboardScreen` using `socket_io_client`. Faculty and Student screens have zero realtime connectivity and rely strictly on manual polling / `RefreshIndicator`.
- **UI Architecture Anomalies:**
  - `faculty_dashboard_screen.dart` is 1,350 lines (45.1 KB), containing countdown timers, QR dispatchers, bottom sheets, washroom state calculations, and extensive widget subtrees.
  - `faculty_duties_screen.dart` is 1,017 lines (34.6 KB).
  - `find_my_seat_screen.dart` is 850 lines (28.2 KB).
  - `seat_details_screen.dart` is completely orphaned and unreferenced in navigation.
