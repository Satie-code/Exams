# EXAMS — API BASELINE INVENTORY

## Implemented Endpoints Inventory

| Method | Route | Controller | Auth Required | Role Required | Request Body / Params | Response | DB Operation | Status |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| `GET` | `/health` | Inline (`app.js`) | No | None | None | `{ message: "EXAMS backend is running" }` | None | IMPLEMENTED |
| `POST` | `/auth/register` | `authController.register` | No | None | `{ email, password, role }` | `{ message, user: { id, email, role } }` | `prisma.user.create`, `student/faculty.create` | IMPLEMENTED |
| `POST` | `/auth/login` | `authController.login` | No | None | `{ email, password }` | `{ access_token, role }` | `prisma.user.findUnique` | IMPLEMENTED |
| `GET` | `/student/exams` | `studentController.getAssignedExams` | Yes (JWT) | `STUDENT` | None (reads `req.user.user_id`) | `{ exams: [ { exam_id, subject, date, time, room, seat } ] }` | `prisma.seatingAllocation.findMany` | IMPLEMENTED |
| `GET` | `/student/seating` | `studentController.getStudentSeating` | Yes (JWT) | `STUDENT` | Query: `?exam_id=<int>` | `{ exam_id, subject, date, time, room, seat }` | `prisma.seatingAllocation.findFirst` | IMPLEMENTED |
| `GET` | `/faculty/duties` | `facultyController.getFacultyDuties` | Yes (JWT) | `FACULTY` | None (reads `req.user.user_id`) | `{ duties: [ { duty_id, exam_id, subject, date, time, room, role, status } ] }` | `prisma.duty.findMany` | IMPLEMENTED |
| `GET` | `/faculty/duty/swap-options` | `facultyController.getDutySwapOptions` | Yes (JWT) | `FACULTY` | Query: `?duty_id=<int>` | `{ duty_id, swap_options: [...] }` | `prisma.duty.findUnique`, `prisma.duty.findMany` | IMPLEMENTED |
| `POST` | `/faculty/duty/swap` | `facultyController.requestDutySwap` | Yes (JWT) | `FACULTY` | `{ requester_duty_id, target_duty_id }` | `{ message, swap_request_id, status, duties: [...] }` | `prisma.$transaction` updating duties to `PENDING_SWAP`, creates `dutySwapRequest`, emits socket | IMPLEMENTED |
| `POST` | `/bundle/scan` | `dashboardController.scanBundle` | Yes (JWT) | `FACULTY` | `{ duty_id, bundle_id }` | `{ message, scan_log_id, scanned_at, bundle: {...} }` | `prisma.bundle.findUnique`, `prisma.$transaction` creating `bundleScanLog` & `activityLog`, emits socket | IMPLEMENTED |
| `POST` | `/attendance` | `dashboardController.markAttendance` | Yes (JWT) | `FACULTY` | `{ duty_id, student_identifier }` | `{ message: "Attendance marked successfully" }` | `prisma.$transaction` creating `attendance` & `activityLog`, emits socket | IMPLEMENTED |
| `POST` | `/supplies/request` | `dashboardController.requestSupplies` | Yes (JWT) | `FACULTY` | `{ duty_id, item, quantity, note }` | `{ message: "Supply request sent successfully" }` | `prisma.$transaction` creating `supplyRequest` & `activityLog`, emits socket | IMPLEMENTED |
| `POST` | `/sos` | `dashboardController.requestSOS` | Yes (JWT) | `FACULTY` | `{ duty_id, message }` (Enum: `ANSWER_SHEETS`, `STATIONERY`, `URGENT_HELP`) | `{ message, sos_request: {...}, pending_count }` | `prisma.$transaction` creating `sOSRequest` & `activityLog`, emits `NEW_SOS` socket | IMPLEMENTED |
| `POST` | `/report` | `dashboardController.submitReport` | Yes (JWT) | `FACULTY` | `{ duty_id, total_students_present, total_answer_sheets_collected, no_incidents, incident_details, remarks, declaration_accepted }` | `{ message, report: {...} }` | `prisma.$transaction` creating `postExamReport` & `activityLog`, emits socket | IMPLEMENTED |
| `POST` | `/washroom/start` | `dashboardController.startWashroomTimer` | Yes (JWT) | `FACULTY` | `{ duty_id, student_id }` | `{ message, washroom_log: {...} }` | `prisma.$transaction` creating `washroomLog` & `activityLog`, emits socket | IMPLEMENTED |
| `POST` | `/washroom/end` | `dashboardController.endWashroomTimer` | Yes (JWT) | `FACULTY` | `{ duty_id, student_id }` | `{ message, washroom_log: {...} }` | `prisma.$transaction` updating `washroomLog` (`endTime`, `status`) & `activityLog`, emits socket | IMPLEMENTED |
| `GET` | `/activity` | `dashboardController.getActivity` | Yes (JWT) | `FACULTY` | Query: `?duty_id=<int>` | `{ duty: {...}, registered_count, max_capacity, pending_sos_count, washroom_logs: [...], activities: [...] }` | `Promise.all` fetching activity logs, washroom logs, SOS count, seating count | IMPLEMENTED |
| `GET` | `/admin/dashboard` | `adminController.getDashboard` | Yes (JWT) | `ADMIN` | None | `{ pending_sos: [...], active_washrooms: [...], recent_activities: [...], pending_swaps: [...] }` | Queries `sOSRequest`, `washroomLog`, `activityLog`, `dutySwapRequest` | IMPLEMENTED |
| `PATCH` | `/admin/swap/approve` | `adminController.approveDutySwap` | Yes (JWT) | `ADMIN` | `{ swap_request_id, approved: <boolean> }` | `{ message, swap_request_id, status }` | `prisma.$transaction` swapping `duty.facultyId` and updating request to `APPROVED`/`REJECTED` | IMPLEMENTED |
| `PATCH` | `/admin/sos/:id/resolve` | `adminController.resolveSOS` | Yes (JWT) | `ADMIN` | Param: `:id` | `{ message, sos_request: {...} }` | `prisma.sOSRequest.update` setting status `RESOLVED` | IMPLEMENTED |

---

## Missing API Endpoints (Required by Product Scope)

1. `GET /student/profile` & `PUT /student/profile` — Student profile reading and updating.
2. `GET /student/notifications` — Notification retrieval.
3. `GET /student/seating/by-urn?urn=<string>&date=<string>` — Dedicated manual URN lookup that matches URN against exam allocations without relying on student token.
4. `GET /faculty/colleagues` — Department directory search for faculty roster.
5. `GET /faculty/profile` — Faculty profile inspection.
6. `GET /admin/users` (and CRUD operations) — Admin user administration.
7. `GET /admin/exams` (and CRUD operations) — Admin exam master data.
8. `GET /admin/rooms` — Room master data.
9. `POST /admin/seating/allocate` — Automated or manual seating generator.
10. `POST /admin/duties/assign` — Automated duty scheduler.
11. `GET /admin/reports` — Post-exam report viewer and data export.
