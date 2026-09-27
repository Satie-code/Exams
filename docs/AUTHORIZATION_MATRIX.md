# EXAMS — AUTHORIZATION MATRIX
**Subsystem:** Security & Access Control  
**Status:** Established Phase 1 Baseline  
**Enforcement Principle:** Server-Side Strict Enforcement (Client UI visibility is purely cosmetic)  

---

## 1. Authentication & Token Architecture

- **Token Type:** JSON Web Token (JWT), HS256 algorithm.
- **Payload Claims:** `{ user_id: number, role: "STUDENT" | "FACULTY" | "ADMIN" }`
- **Transport:** HTTP `Authorization: Bearer <token>` header.
- **Middleware:** `backend/middleware/authMiddleware.js`:
  - `verifyToken`: Validates JWT signature, expiration, and extracts claims into `req.user`.
  - `allowRoles(...roles)`: Enforces role-based access control (RBAC).

---

## 2. Global Role-Based Access Control (RBAC) Matrix

| Endpoint Route | HTTP Method | Role Requirement | Description | Enforcement Location |
|---|---|---|---|---|
| `/auth/register` | `POST` | Public (Unauthenticated) | Registers student, faculty, or admin | `controllers/authController.js` |
| `/auth/login` | `POST` | Public (Unauthenticated) | Authenticates credentials and issues JWT | `controllers/authController.js` |
| `/health` | `GET` | Public (Unauthenticated) | Service health check | `backend/app.js` |
| `/student/exams` | `GET` | `STUDENT` | Retrieves scheduled exams for authenticated student | `routes/studentRoutes.js` + `studentController.js` |
| `/student/seating` | `GET` | `STUDENT` | Retrieves hall and seat allocation for authenticated student | `routes/studentRoutes.js` + `studentController.js` |
| `/faculty/duties` | `GET` | `FACULTY` | Retrieves assigned invigilation duties | `routes/facultyRoutes.js` + `facultyController.js` |
| `/faculty/swap/options` | `GET` | `FACULTY` | Lists swap candidate duties from colleagues | `routes/facultyRoutes.js` + `facultyController.js` |
| `/faculty/swap/request` | `POST` | `FACULTY` | Initiates a duty swap request | `routes/facultyRoutes.js` + `facultyController.js` |
| `/bundle/scan` | `POST` | `FACULTY` | Scans exam bundle manifest QR code | `routes/bundleRoutes.js` + `services/bundleService.js` |
| `/attendance/mark` | `POST` | `FACULTY` | Marks student attendance | `routes/attendanceRoutes.js` + `services/attendanceService.js` |
| `/supplies/request` | `POST` | `FACULTY` | Requests exam supplies (sheets, threads, pens) | `routes/supplyRoutes.js` + `services/supplyService.js` |
| `/sos/request` | `POST` | `FACULTY` | Submits emergency SOS assistance alert | `routes/sosRoutes.js` + `services/sosService.js` |
| `/report/submit` | `POST` | `FACULTY` | Submits post-exam invigilation report | `routes/reportRoutes.js` + `services/reportService.js` |
| `/washroom/start` | `POST` | `FACULTY` | Starts timer for student washroom break | `routes/washroomRoutes.js` + `services/washroomService.js` |
| `/washroom/end` | `POST` | `FACULTY` | Ends timer and logs violation/returned status | `routes/washroomRoutes.js` + `services/washroomService.js` |
| `/activity` | `GET` | `FACULTY` | Retrieves operational summary and recent activity feed | `routes/activityRoutes.js` + `services/dashboardService.js` |
| `/admin/dashboard` | `GET` | `ADMIN` | Retrieves institution-wide operational metrics | `routes/adminRoutes.js` + `controllers/adminController.js` |
| `/admin/swap/approve` | `PATCH` | `ADMIN` | Approves or rejects pending duty swap | `routes/adminRoutes.js` + `controllers/adminController.js` |
| `/admin/sos/:id/resolve` | `PATCH` | `ADMIN` | Resolves active SOS emergency incident | `routes/adminRoutes.js` + `controllers/adminController.js` |

---

## 3. Object-Level Authorization & Data Ownership

In addition to role checks, the server enforces strict object-level data boundaries:

1. **Faculty Duty Ownership:**
   - Evaluated by: `dutyService.getFacultyDutyOrThrow(userId, dutyId)`.
   - Invariant: A faculty user cannot scan bundles, mark attendance, request supplies, or start washroom timers for a `dutyId` not assigned to their own `facultyId`. (Returns `404 Duty not found for this faculty member`).
2. **Duty Swap Integrity:**
   - Evaluated by: `facultyController.requestSwap`.
   - Invariant: The requester must own `requesterDutyId`. Target duty must not belong to requester. Both duties must have status `CONFIRMED`.
3. **Student Profile Scoping:**
   - Evaluated by: `studentController.getStudentSeating`.
   - Invariant: Student seating queries resolve `studentId` strictly from `req.user.user_id`, preventing horizontal privilege escalation (IDOR).
