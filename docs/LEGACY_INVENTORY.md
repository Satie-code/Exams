# EXAMS — LEGACY & OBSOLETE CODE INVENTORY

## 1. Evaluation of Former Technology Stack
A comprehensive search was performed across all directories, file extensions (`*.py`, `alembic.ini`, `requirements.txt`, `Pipfile`), and Git commit history for remnants of:
- Python
- FastAPI
- SQLAlchemy
- Alembic

### Findings
- **Repository Working Copy:** 0 Python files, 0 Alembic configurations, 0 SQLAlchemy schemas found (with the sole exception of standard internal Flutter SDK helper `flutter_lldb_helper.py` in ephemeral build cache).
- **Git History (10 commits):** Zero commits ever introduced or referenced Python, FastAPI, Alembic, or SQLAlchemy.
- **Classification:** **OBSOLETE / NON-EXISTENT IN REPOSITORY**. The former technology stack exists only as a conceptual note in project documentation requirements. No code cleanup or refactoring is needed for this stack.

---

## 2. Legacy / Obsolete Code Register

| Item / File | Technology | Current Usage | Conflict with Final Architecture | Recommended Future Action |
| :--- | :--- | :--- | :--- | :--- |
| `frontend/exams/lib/screens/seat_details_screen.dart` | Flutter / Dart | **DEAD / UNREACHABLE.** Never imported or navigated to from any screen. | Deprecated by inline `_StudentResultCard` inside `find_my_seat_screen.dart`. | Remove in Phase 1 after confirming no external navigation links exist. |
| `backend/test_admin.js` | Node.js script | **SCRATCH SCRIPT.** Manual test script testing `/auth/login` and `/admin/dashboard`. | Ad-hoc testing file residing directly inside backend root. | Relocate to `backend/scripts/` or delete in Phase 1 once integration test suite is established. |
| `package.json` (Repository root) | npm / Prisma | **CONFUSED / REDUNDANT.** Defines Prisma `6.19.2` and `@prisma/client: ^7.5.0` at the repository root. | Conflicts with `backend/package.json` which uses Prisma `6.5.0`. Triggers version ambiguity when executing CLI commands from root. | Consolidate in Phase 1 to ensure workspace root either acts as an explicit npm workspace or delegates entirely to `backend/`. |
| `.github/modernize/java-upgrade/` | GitHub Automation | **SUSPICIOUS TOOLING.** Automated Java upgrade scripts. | Unrelated to core EXAMS Node.js/Express and Flutter architecture. | Audit in Phase 1 for repository cleanup. |
| `c:\Exams\238793.log` | Text log | **STRAY ARTIFACT.** Transient log file left in workspace root. | Violates clean repository hygiene. | Clean up and ensure `.gitignore` enforcement in Phase 1. |
