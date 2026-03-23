# EXAMS

Production-focused exam operations system with:

- Backend: Node.js + Express + Prisma + PostgreSQL
- Frontend: Flutter
- Roles: STUDENT, FACULTY, ADMIN

## 1. Backend Setup

1. Copy `backend/.env.example` to `backend/.env`
2. Install dependencies:

```powershell
cd backend
cmd /c npm.cmd install
```

3. Run Prisma generate and migrations:

```powershell
cmd /c npx prisma generate
cmd /c npx prisma migrate dev
```

4. Seed demo data:

```powershell
cmd /c npm.cmd run prisma:seed
```

5. Start the backend:

```powershell
cmd /c npm.cmd start
```

The backend runs on `http://localhost:5000` by default.

## 2. Demo Accounts

All seeded accounts use the same password:

- `student@exams.local` / `Pass123!`
- `faculty@exams.local` / `Pass123!`
- `faculty2@exams.local` / `Pass123!`
- `admin@exams.local` / `Pass123!`

Faculty demo bundle:

- `BND-MATH101-001`

## 3. Flutter Setup

```powershell
cd frontend/exams
flutter pub get
flutter run
```

Default backend URLs:

- Android emulator: `http://10.0.2.2:5000`
- iOS simulator / desktop / web: `http://localhost:5000`

For a physical device, pass your machine IP:

```powershell
flutter run --dart-define=API_BASE_URL=http://192.168.1.10:5000
```

If no token is provided at launch, the app now opens a login screen automatically.

## 4. Notes

- Android cleartext HTTP is enabled for local testing.
- iOS App Transport Security is relaxed for local HTTP testing.
- Prisma uses `DATABASE_URL`, so make sure the value in `backend/.env` is valid for your PostgreSQL instance.
