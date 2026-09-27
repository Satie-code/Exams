# EXAMS Backend Service

REST API & Realtime Service for the EXAMS operations platform built with **Node.js**, **Express**, **Prisma ORM**, **PostgreSQL**, and **Socket.IO**.

---

## 1. Prerequisites

- **Node.js**: v18+ (tested on v24)
- **PostgreSQL**: v15+ (tested on PostgreSQL 18)
- Optional: **Docker** & **Docker Compose**

---

## 2. Environment Configuration

Create a `.env` file in the `backend/` directory by copying `.env.example`:

```powershell
cp .env.example .env
```

Configure your environment variables:

```env
PORT=5000
DATABASE_URL="postgresql://postgres:Satie%40postgres%4021@localhost:5432/exams_db?schema=public"
JWT_SECRET=your_secure_jwt_secret_key
JWT_EXPIRES_IN=1d
```

> **Note on Special Characters in Passwords**:
> If your database password contains special characters such as `@`, they must be percent-encoded (e.g. `@` becomes `%40`) so that URL parsers correctly read the host and port.

---

## 3. Database Setup & Seeding

1. **Install dependencies**:
   ```powershell
   npm install
   ```

2. **Generate Prisma Client**:
   ```powershell
   npm run prisma:generate
   ```

3. **Sync database schema**:
   ```powershell
   npm run prisma:push
   ```

4. **Seed demo data**:
   ```powershell
   npm run prisma:seed
   ```

*(Alternatively, run `npm run setup` to generate the client and push the schema in a single command).*

---

## 4. Running the Backend

- **Start server**:
  ```powershell
  npm start
  ```
- **Development mode** (auto-reload with nodemon):
  ```powershell
  npm run dev
  ```

The server listens on **`http://localhost:5000`**.

### Verify Server Status
```powershell
curl http://localhost:5000/health
```
Expected response:
```json
{"message":"EXAMS backend is running"}
```

---

## 5. Seeded Demo Accounts

All seeded accounts use password: `Pass123!`

| Role | Email | Password | Details |
|------|-------|----------|---------|
| **ADMIN** | `admin@exams.local` | `Pass123!` | Access to dashboard, SOS alerts, swap approvals |
| **FACULTY** | `faculty@exams.local` | `Pass123!` | Assigned to active bundle `BND-MATH101-001` |
| **FACULTY** | `faculty2@exams.local` | `Pass123!` | Alternate faculty for duty swap requests |
| **STUDENT** | `student@exams.local` | `Pass123!` | Hall ticket and exam schedule access |

---

## 6. Running Tests

Execute the Jest test suite:

```powershell
npm test
```

---

## 7. Optional: Running PostgreSQL via Docker

If you prefer to run PostgreSQL in a container rather than a local installation:

```powershell
docker compose up -d
```

This launches the database container on port `5432` with credentials defined in [`docker-compose.yml`](docker-compose.yml).

---

## 8. Troubleshooting

- **EPERM / File Lock Error on Windows**:
  If you see `EPERM: operation not permitted, rename ... query_engine-windows.dll.node`, an existing Node process is currently running and holding a lock on the Prisma engine DLL. Stop any running Node processes or servers before running `prisma generate`.
- **Port 5000 in Use**:
  Check if an existing backend instance is running:
  ```powershell
  Get-NetTCPConnection -LocalPort 5000 -ErrorAction SilentlyContinue
  ```
