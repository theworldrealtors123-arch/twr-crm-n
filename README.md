# TWR CRM — TWR REAL ESTATE

Mobile CRM: Flutter app + NestJS API + PostgreSQL.

- **[docs/README.md](docs/README.md)** — architecture and stack
- **[docs/SETUP.md](docs/SETUP.md)** — install, run, build (start here)
- **[docs/API.md](docs/API.md)** — endpoint reference and permission matrix
- **[docs/DATABASE.md](docs/DATABASE.md)** — schema, indexes, migrations
- **[docs/BUILD_APK.md](docs/BUILD_APK.md)** — building the Android APK
- **[PROGRESS.md](PROGRESS.md)** — Day 1 status: what is verified, what is not

```bash
docker compose -f database/docker-compose.yml up -d
cd backend && npm install && cp .env.example .env && npm run migration:run && npm run seed && npm run start:dev
cd ../mobile && flutter pub get && flutter run --dart-define=API_BASE_URL=http://10.0.2.2:3000/api/v1
```

Login: `manager@twrrealestate.ae` / `Twr@12345`
