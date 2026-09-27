# EXAMS — ENVIRONMENT BASELINE

## 1. System Runtime & Tool Versions
- **Operating System:** Windows 11 Pro / Enterprise (x86_64)
- **Node.js:** `v24.13.0`
- **npm:** `11.6.2`
- **Flutter SDK:** `3.38.9` (Channel stable, revision `67323de285`)
- **Dart SDK:** `3.10.8` (DevTools `2.51.1`)
- **Docker:** Docker Desktop installed (daemon currently stopped)
- **PostgreSQL Requirement:** PostgreSQL 17 (per `backend/docker-compose.yml`)
- **Express.js:** `^4.19.2`
- **Prisma CLI / Client (backend):** `^6.5.0`
- **Prisma Client (root package.json):** `^7.5.0` (DISCREPANCY DETECTED)

---

## 2. Environment Variables & Secret Handling

### Backend Environment Configuration
- **Example File:** `backend/.env.example`
  - Defines:
    - `PORT=5000`
    - `DATABASE_URL="postgresql://postgres:password@localhost:5432/exams_db?schema=public"`
    - `JWT_SECRET=your_jwt_secret_key_here`
    - `JWT_EXPIRES_IN=1d`
- **Active Environment File:** `backend/.env`
  - Status: Present on local disk.
  - Verification: Excluded from Git tracking via `.gitignore`.
  - Security Finding: `SECRET FOUND IN FILE: backend/.env` (DATABASE_URL credentials, JWT_SECRET value).
- **Container Environment:** `backend/docker-compose.yml`
  - Security Finding: `SECRET FOUND IN FILE: backend/docker-compose.yml` (POSTGRES_PASSWORD hardcoded in plaintext).

### Frontend Environment Configuration
- Configuration passed via `--dart-define` at runtime:
  - `API_BASE_URL`: Defaults to `http://10.0.2.2:5000` on Android, `http://localhost:5000` on iOS/Web/Desktop.
  - `ACCESS_TOKEN`: Optional override for headless testing.
  - `USER_ROLE`: Optional override for headless testing.
- Platform Security Flags:
  - Android (`AndroidManifest.xml`): `android:usesCleartextTraffic="true"` (Permits unencrypted HTTP communication).
  - iOS (`Info.plist`): `NSAppTransportSecurity` contains `NSAllowsArbitraryLoads = true` (Permits unencrypted HTTP communication).

---

## 3. Discrepancies & Anomalies
1. **Redundant Root `package.json`:**
   - Root `package.json` specifies `"@prisma/client": "^7.5.0"` and `"prisma": "^6.19.2"`.
   - `backend/package.json` specifies `"@prisma/client": "^6.5.0"` and `"prisma": "^6.5.0"`.
   - Running `npx prisma` at the workspace root triggers global resolution attempts for Prisma 8 / 7 instead of using backend's Prisma 6.
2. **Untracked Log File:**
   - `c:\Exams\238793.log` exists in workspace root, despite `*.log` existing in `.gitignore`.
