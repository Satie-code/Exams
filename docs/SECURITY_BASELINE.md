# EXAMS — SECURITY BASELINE

## 1. Classification Methodology
Findings are prioritized using standard risk ratings:
- **CRITICAL:** Immediate compromise or credential exposure risk.
- **HIGH:** Architectural vulnerability leading to bypass of access control or integrity loss.
- **MEDIUM:** Weak configuration or sensitive information leakage.
- **LOW:** Defense-in-depth gaps.
- **INFO:** Design observations and best-practice recommendations.

---

## 2. Findings Register

### [CRITICAL] SEC-01: Hardcoded Secrets in Tracked Docker Configuration
- **Location:** `backend/docker-compose.yml` (line 9)
- **Detail:** `SECRET FOUND IN FILE: backend/docker-compose.yml`
- **Impact:** Production/local database credentials committed directly to version control. Anyone with read access to the repository has access to the default database password.
- **Phase 0 Status:** Documented only. DO NOT alter in Phase 0.

### [CRITICAL] SEC-02: Plaintext Credentials in Local Environment
- **Location:** `backend/.env`
- **Detail:** `SECRET FOUND IN FILE: backend/.env`
- **Impact:** Production database strings and JWT signing secrets stored in unencrypted `.env` files. While `.gitignore` correctly ignores `.env`, presence of real credentials in development workstations without key rotation policies poses leakage risks.
- **Phase 0 Status:** Verified that `.env` is ignored by Git.

### [HIGH] SEC-03: Student Seating Lookup Ignores URN (Client-Side Bypassed Logic)
- **Location:** `frontend/exams/lib/screens/find_my_seat_screen.dart` (lines 94-133) & `backend/controllers/studentController.js` (lines 51-94)
- **Detail:** The UI presents a "University Registration Number (URN)" input field and validates it client-side. However, the subsequent network call executes `GET /student/seating?exam_id=<id>` without transmitting the URN. The backend solely filters by `req.user.user_id`.
- **Impact:** Misleading UX and potential IDOR/authorization inconsistency if an invigilator or student attempts to look up seating by registration number without a matching authenticated session.

### [HIGH] SEC-04: Cleartext HTTP Communication Permitted on Mobile Clients
- **Location:**
  - `frontend/exams/android/app/src/main/AndroidManifest.xml` (line 9: `android:usesCleartextTraffic="true"`)
  - `frontend/exams/ios/Runner/Info.plist` (lines 48-52: `NSAllowsArbitraryLoads = true`)
- **Detail:** Cleartext network traffic is allowed on both Android and iOS platforms to facilitate local development.
- **Impact:** In transit, tokens, student identifiers, bundle codes, and examination credentials are vulnerable to man-in-the-middle (MITM) eavesdropping and manipulation on untrusted Wi-Fi/networks unless HTTPS is enforced.

### [HIGH] SEC-05: Wildcard CORS Configuration
- **Location:** `backend/app.js` (line 29: `app.use(cors())`) & `backend/config/socket.js` (lines 8-11: `origin: "*"`)
- **Detail:** Cross-Origin Resource Sharing is unrestricted (`*`) on both the REST API and the WebSocket server.
- **Impact:** Malicious web applications hosted on other domains can execute authenticated cross-origin requests if cookies/tokens are accessible.

### [HIGH] SEC-06: Database Applied via `db push` without Migration Auditing
- **Location:** `backend/package.json` (`npm run prisma:push`)
- **Detail:** The project has no `backend/prisma/migrations/` directory. Schema alterations are pushed directly using `prisma db push`.
- **Impact:** No change history, no migration rollback capabilities, and high risk of catastrophic accidental column or table drops in production.

### [MEDIUM] SEC-07: Hardcoded Test Account Credentials in Client UI
- **Location:** `frontend/exams/lib/screens/login_screen.dart` (lines 27-28 & 180-187)
- **Detail:** Test account credentials (`faculty@exams.local / Pass123!`, `student@exams.local`, `admin@exams.local`) and default text field inputs are embedded in the shipped Flutter source.
- **Impact:** If built for staging/production, test accounts and demo passwords are automatically exposed to end users.

### [MEDIUM] SEC-08: Destructive Reset in Database Seed Script
- **Location:** `backend/prisma/seed.js` (lines 37-53)
- **Detail:** `resetData()` executes unqualified `deleteMany()` across all 15 database tables.
- **Impact:** If `prisma:seed` is accidentally triggered against a staging or production database, all examination, user, attendance, and log records are permanently erased.

### [LOW] SEC-09: Unsegmented Rate Limiting on Authentication Endpoints
- **Location:** `backend/app.js` (lines 32-39)
- **Detail:** A global limiter allows 200 requests per 15 minutes across all routes.
- **Impact:** No specialized strict rate limiting on `/auth/login` or `/auth/register` to prevent credential stuffing or brute force attacks.

### [LOW] SEC-10: WebSocket Authorization Restricted to Role Name in Token
- **Location:** `backend/config/socket.js` (lines 24-26)
- **Detail:** Sockets inspect `decoded.role !== "ADMIN"`. User existence or account active status is not validated against the database upon connection.
