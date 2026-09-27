# EXAMS — FEATURE IMPLEMENTATION STATUS

## 1. Student Subsystem
| Feature | Implementation Status | Notes / Baseline Reality |
| :--- | :--- | :--- |
| **Authentication** | IMPLEMENTED | Email + password login via `/auth/login`, JWT issued, role verified |
| **Dashboard / Home** | PARTIALLY IMPLEMENTED | `FindMySeatScreen` serves as initial landing page; no separate summary dashboard |
| **Exams** | IMPLEMENTED | `/student/exams` returns assigned exams from `seatingAllocation` |
| **Schedule** | MOCKED | `student_schedule_screen.dart` renders a hardcoded 3-item exam list |
| **Seating** | PARTIALLY IMPLEMENTED | Fetches seat by `exam_id` using JWT token; URN input field is completely ignored |
| **Profile** | MOCKED / PLACEHOLDER | `student_profile_screen.dart` hardcodes "Roll Number: U194849" and dummy action buttons |
| **Notifications** | MISSING | No notification model, endpoint, or client UI |

---

## 2. Faculty Subsystem
| Feature | Implementation Status | Notes / Baseline Reality |
| :--- | :--- | :--- |
| **Authentication** | IMPLEMENTED | Email + password login, JWT stored in secure storage |
| **Dashboard** | IMPLEMENTED | Live operational dashboard with exam timers, break monitoring, quick scans |
| **Duties** | IMPLEMENTED | `/faculty/duties` returns assigned duties with subject, room, timing |
| **Duty History** | PARTIALLY IMPLEMENTED | Client-side tab filters `duty.isHistory`; no distinct backend history route |
| **Duty Exchange** | IMPLEMENTED | `/faculty/duty/swap-options` and `POST /faculty/duty/swap` with transactions |
| **Bundle Scanning** | IMPLEMENTED | Point-of-action QR scan validates `bundle_id` matching exam and room |
| **Attendance** | IMPLEMENTED | Marked manually or via QR/barcode scanner to `/attendance` |
| **Washroom Tracking** | IMPLEMENTED | Live start/stop timers with 5-min warning and 10-min violation thresholds |
| **Recent Activity** | IMPLEMENTED | `/activity` returns last 10 activity log records for room/duty |
| **SOS Emergency** | IMPLEMENTED | Broadcasts `ANSWER_SHEETS`, `STATIONERY`, `URGENT_HELP` via API and Socket.IO |
| **Supplies** | IMPLEMENTED | Request supply item with quantity and note via `/supplies/request` |
| **Incidents** | PARTIALLY IMPLEMENTED | Captured as text inside post-exam report; no standalone incident reporting |
| **Post-Exam Report** | IMPLEMENTED | Form submission enforcing headcount, sheets count, incident text, and declaration |

---

## 3. Admin Subsystem
| Feature | Implementation Status | Notes / Baseline Reality |
| :--- | :--- | :--- |
| **Authentication** | IMPLEMENTED | Role `ADMIN` verified via JWT |
| **Dashboard** | PARTIALLY IMPLEMENTED | Command Center renders active SOS, pending swaps, and activity feed |
| **Users** | MISSING | No user management API or UI |
| **Students** | MISSING | No student CRUD or enrollment management |
| **Faculty** | MISSING | No faculty roster or departmental CRUD |
| **Rooms** | MISSING | Rooms are plain strings on duties/allocations; no master entity |
| **Exams** | MISSING | No exam creation, scheduling, or master data management |
| **Seating** | MISSING | No admin seating allocator UI or generation engine |
| **Duties** | MISSING | No duty assignment engine; admin only approves/rejects swaps |
| **Bundles** | MISSING | No bundle generation or QR manifest generation |
| **Attendance Monitoring** | PARTIALLY IMPLEMENTED | Passively visible through live activity stream only |
| **Washroom Monitoring** | BROKEN / PARTIALLY IMPLEMENTED | `/admin/dashboard` returns `active_washrooms`, but UI never renders it |
| **SOS Management** | IMPLEMENTED | Live alert reception and resolve action via `PATCH /admin/sos/:id/resolve` |
| **Supplies Management** | MISSING | Supplies appear in activity stream but have no dedicated fulfillment UI |
| **Incidents Management** | MISSING | No consolidated incidents oversight |
| **Reports** | MISSING | No admin view to inspect or export submitted post-exam reports |
| **Notifications** | MISSING | No push or in-app notification center |
| **Audit Logs** | MISSING | `activity_logs` table exists, but no administrative audit log viewer |
