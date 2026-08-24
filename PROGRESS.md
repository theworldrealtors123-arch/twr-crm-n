# TWR CRM — Day 1 Progress

**Date:** 24 August 2026
**Scope:** Day 1 — authentication, dashboard, lead management

---

## Honest summary first

The **backend is complete and verified**. It was built, migrated, seeded, compiled, tested, and exercised over live HTTP against a real PostgreSQL 16 database. Every claim about it below is backed by a command that was actually run.

The **Flutter application is written in full but has not been compiled**. The build environment used for Day 1 had no network access to the Flutter SDK host, so `flutter pub get`, `flutter analyze`, `flutter test`, and `flutter build apk` could not be executed. The Dart source is complete — 40 files covering every Day 1 screen, plus 3 test files — but it should be treated as **unverified until it compiles on your machine**. Expect a short round of fixes on first run; see [First run on the mobile app](#first-run-on-the-mobile-app).

Per the instruction not to claim anything is complete unless it actually works, the mobile side is listed under *written but unverified*, not under *working*.

---

## Working and verified

### Authentication
- `POST /auth/login` — bcrypt verification, returns access + refresh tokens and the user with permissions
- `POST /auth/refresh` — validates, **rotates** (old token revoked immediately), issues a new pair
- `POST /auth/logout` — revokes the presented refresh token, or all tokens for the user
- `GET /users/me` — profile with permission list
- Wrong password, unknown email, tampered token, and missing token all return 401
- Unknown email and wrong password return the *same* message, so login cannot enumerate accounts
- Deactivating a user revokes access on their next request

### Database
- PostgreSQL schema created by a hand-written TypeORM migration — **35 statements, verified to run from scratch on an empty database and to roll back cleanly**
- 10 tables: `roles`, `permissions`, `role_permissions`, `users`, `user_roles`, `refresh_tokens`, `leads`, `lead_notes`, `lead_activities`, `migrations`
- UUID primary keys, foreign keys with deliberate delete behaviour, unique constraints, 13 indexes, 2 check constraints
- `synchronize` permanently disabled — the schema can only change through a migration

### Leads
- Create, read (paginated + scoped), update, delete
- Search by name, phone, WhatsApp, or email — executed in SQL, never client-side
- Filter by status, priority, source, property type, assigned agent; sortable
- Pagination enforced server-side; `limit > 100` is rejected, so the API can never be made to dump the table
- Status change, agent assignment and reassignment, notes
- Full activity timeline with user, timestamp, type, description, and structured `from`/`to` metadata
- Every mutation writes its activity **inside the same transaction**, so the timeline cannot drift from the record

### Permissions (enforced server-side)
- Three guard layers — authentication, role, permission key — plus row-level scoping in the service
- Agent A requesting Agent B's lead by id gets **404** (not 403 — a 403 would confirm the record exists); same for update, note, status change, and activities
- An agent filtering the list by another agent's id gets an empty page, not a leak
- An agent cannot reassign a lead, including by sending `assignedAgentId` to `PATCH /leads/:id`
- A lead created by an agent is auto-assigned to that agent
- Managers see the whole team pipeline; admins and super admins see everything; only admins can delete
- Leads can only be assigned to active users holding the `AGENT` role

### Dashboard
- `GET /dashboard/stats` — total, new, hot, follow-ups, contacted, closed, plus status and source breakdowns
- Every figure is a SQL aggregate over the live `leads` table. **Nothing is hard-coded.** A test asserts the API's numbers equal a direct `SELECT COUNT(*)`
- Scoped per role: agents see only their own book (`scope: "ASSIGNED_TO_ME"`)
- Correct against an empty database — returns zeros, not errors

### Security
- bcrypt hashing (cost 12 default, configurable); plaintext passwords never stored, logged, or returned
- Refresh tokens persisted only as SHA-256 hashes — a database leak cannot be replayed
- Login rate limited to 10 attempts/minute/IP; global throttling elsewhere
- `helmet` headers, explicit CORS allowlist, HTTPS-ready configuration
- Global `ValidationPipe` with `whitelist` + `forbidNonWhitelisted` — unknown properties rejected, not ignored
- All secrets in `.env` (git-ignored); `.env.example` committed with placeholders only

### Documentation
- Swagger/OpenAPI live at `/api/v1/docs`
- `docs/README.md`, `docs/SETUP.md`, `docs/API.md`, `docs/DATABASE.md`
- `database/docker-compose.yml` and a generated `database/schema.sql`

---

## Test results

| Suite | Result |
|---|---|
| TypeScript compilation (`tsc --noEmit`) | **passed**, 0 errors |
| Backend build (`nest build`) | **passed** |
| Backend unit tests (Jest) | **8 passed**, 0 failed |
| Backend e2e tests (Jest + Supertest, real PostgreSQL) | **47 passed**, 0 failed |
| Migration run from empty database | **passed** (35 statements) |
| Migration revert | **passed** |
| Live HTTP walkthrough of the full Day 1 flow | **passed** |
| Flutter analyze | **not run** — SDK unavailable in the build environment |
| Flutter tests | **not run** — same reason |

**Total: 55 automated backend tests passing, 0 failing.**

The e2e suite runs against a dedicated `twr_crm_test` database and covers: login, invalid password, unknown email, payload validation, token refresh and rotation, rotated-token rejection, logout revocation, unauthenticated 401s, role authorisation, lead create/read/update/delete, pagination limits, search by three fields, filters, status change, assignment and reassignment, notes, activity creation and ordering, cross-agent isolation, and empty-database behaviour.

### Live flow verified over HTTP

```
health          → {"status":"ok","database":"up"}
bad login       → 401
login (manager) → Khalid Rahman / SALES_MANAGER
no token        → 401
dashboard       → total=20  new=3  hot=7  followups=7   (from SQL)
agents          → Ali Hassan, Fatima Noor, Rajesh Kumar
create lead     → 447a38f5-f0e2-4e1c-83ca-7153360b7354
search          → 1 match: Smoke Test Customer [NEW/HOT]
assign          → assigned to Ali Hassan
edit            → Palm Jumeirah / AED 2,100,000
status          → CONTACTED
note            → saved
timeline        → LEAD_CREATED → ASSIGNED → LEAD_UPDATED → STATUS_CHANGED → NOTE_ADDED
refresh         → new token pair issued
isolation       → other agent reading that lead → 404
swagger         → 200
database        → leads=21  notes=3  activities=64  users=6
```

### Two real bugs found by testing and fixed

1. **Stale relation overwrote the foreign key.** On reassignment, TypeORM's eagerly loaded `assignedAgent` object took precedence over the updated `assigned_agent_id`, so the database silently kept the *previous* agent. Fixed by writing columns explicitly with `update()` instead of `save()` on a loaded entity.
2. **`PartialType` leaked DTO defaults into PATCH.** Because `UpdateLeadDto extends PartialType(CreateLeadDto)`, a partial update also applied the create defaults — patching one field silently reset `source`, `status`, and `priority`. Fixed by moving defaults out of the DTO into the service and schema. Two regression tests now guard it.

Both were caught because the tests assert against database state, not against the API's own response.

---

## Written but not yet verified — Flutter application

All Day 1 screens and logic are implemented in Dart (40 files):

- **Splash** — restores a session from secure storage, routes to Dashboard or Login
- **Login** — TWR branding, validation, error display, loading state, responsive down to small phones
- **Dashboard** — greeting by time of day and first name, four stat cards from the API, pipeline breakdown, pull to refresh
- **Bottom navigation** — Home / Leads / Profile, built role-aware so Day 2 modules can be added without touching screens
- **Leads list** — debounced search (400 ms), filter sheet with badge count, infinite scroll pagination, loading / empty / error / retry states
- **Create & edit lead** — every specified field, client validation mirroring the backend, agent assignment visible only to authorised roles
- **Lead details** — header with status and priority, CALL and WHATSAPP buttons (real device intents, no fabricated call records), customer info, requirement, budget, pipeline, notes newest-first, activity timeline
- **Action sheets** — status picker, agent picker, note composer
- **Profile** — user, role, permissions, logout with confirmation
- **Networking** — Dio client that attaches the token, refreshes once on 401, retries the original request, and returns to Login only when refresh fails; all errors normalised, including "Unable to connect. Please try again."
- **Storage** — tokens in the platform keychain/keystore; passwords never stored on the device
- **Tests written** (3 files, ~40 cases) — login rendering and validation, auth state transitions, lead list rendering and empty/error states, search, create-lead validation, provider behaviour, navigation, formatters and validators. All use fake services, so they run offline.

### First run on the mobile app

```bash
cd mobile
flutter pub get
flutter analyze          # expect a small number of fixes here
flutter test
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:3000/api/v1
```

Three version-fragile APIs were removed after the first review, so the most likely
compile breaks are already gone:

- **`ThemeData.cardTheme`** dropped — the `CardTheme` / `CardThemeData` type change
  across Flutter versions was the single most likely break. Card styling now lives
  in `shared/widgets/app_card.dart`.
- **`Color.withValues`** (Flutter 3.27+) replaced by `AppColors.alpha()`, built from
  `Color.fromRGBO` so it compiles on any SDK.
- **`PopScope.onPopInvokedWithResult`** (Flutter 3.24+) removed; the details screen
  returns its result directly.

What may still need attention on first run:

1. Package API drift in `dio` or `provider` if they resolve to majors newer than pinned.
2. Lint warnings from `analysis_options.yaml` — warnings only, they do not block a build.

---

## Not yet implemented (Day 2 and later)

- Follow-ups module
- Tasks
- Attendance
- Projects
- Properties / inventory
- Calling integration and call recordings
- WhatsApp Business integration
- Reports and analytics
- Meta Ads lead-form integration
- HR module (the `HR` role is seeded but has no module)
- Password reset flow (the Login screen currently directs users to their administrator)
- Push notifications
- File and document attachments on leads
- iOS build verification
- CI pipeline

---

## Known limitations

- **Search does not scale indefinitely.** `LOWER(column) LIKE '%term%'` cannot use a B-tree index. Fine at Day 1 volumes; move to a `pg_trgm` GIN index or full-text search before the lead table gets large.
- **"Team" is currently the whole organisation.** There is no `manager_id` on `users`, so a `SALES_MANAGER` sees every lead rather than a specific team's. Adding real team boundaries is a schema change plus one scoping clause.
- **CALL and WHATSAPP open device intents only.** No call logging or message history is recorded — deliberately, since fabricating those was explicitly out of scope.
- **Refresh-token rotation is single-device-friendly but strict.** Two devices sharing one refresh token will fight; each login issues its own token, so this only appears if a token is copied between devices.
- **`user_roles` exists but is unused.** It is in place for future multi-role support; Day 1 uses the single `users.role_id`.

---

## Commands

```bash
# Database
docker compose -f database/docker-compose.yml up -d

# Backend
cd backend
npm install
cp .env.example .env          # set DB_PASSWORD and both JWT secrets
npm run migration:run
npm run seed
npm run start:dev             # http://localhost:3000/api/v1
npm run typecheck && npm test && npm run test:e2e

# Mobile
cd mobile
flutter pub get
flutter analyze && flutter test
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:3000/api/v1
flutter build apk --release --dart-define=API_BASE_URL=https://api.twrrealestate.ae/api/v1
```

Seed logins — all with password `Twr@12345`:
`superadmin@` · `admin@` · `manager@` · `ali.agent@` · `fatima.agent@` · `rajesh.agent@` **twrrealestate.ae**

---

## Suggested Day 2 order

1. Run `flutter analyze` and `flutter test`, fix what surfaces, and confirm the full login → dashboard → lead → note → timeline loop on a device. Nothing else should start before the loop is proven end to end.
2. Add `manager_id` to `users` and tighten manager scoping to real teams.
3. Follow-ups module — the `next_followup_at` column and the dashboard count already exist, so this is mostly UI.
4. Tasks, then Properties/Projects.
5. Meta Ads webhook ingestion into the existing `META_ADS` source.
