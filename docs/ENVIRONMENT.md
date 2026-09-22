# Environment Variables Reference

## Backend Environment Variables (`backend/.env`)

| Variable Name | Description | Default / Example Value |
|---|---|---|
| `NODE_ENV` | Application environment mode (`development`, `production`, `test`) | `development` |
| `PORT` | HTTP port for Express server | `5000` |
| `API_PREFIX` | Prefix for all REST API routes | `/api/v1` |
| `CLIENT_URL` | Comma-separated allowed frontend origins for CORS | `http://localhost:3000,http://localhost:8080` |
| `MONGODB_URI` | MongoDB connection string | `mongodb://127.0.0.1:27017/finance_saas_db` |
| `JWT_SECRET` | Secret key for signing access tokens | `<strong-random-key>` |
| `JWT_EXPIRES_IN` | Validity duration of access tokens | `7d` |
| `JWT_REFRESH_SECRET` | Secret key for signing refresh tokens | `<strong-refresh-key>` |
| `JWT_REFRESH_EXPIRES_IN` | Validity duration of refresh tokens | `30d` |
| `BCRYPT_SALT_ROUNDS` | Salt rounds for password hashing | `10` |
| `SUPER_ADMIN_NAME` | Initial Platform Super Admin Name | `Platform Super Admin` |
| `SUPER_ADMIN_EMAIL` | Initial Super Admin Email | `superadmin@financesaas.com` |
| `SUPER_ADMIN_PASSWORD` | Initial Super Admin Password | `SuperAdmin@2026!` |
| `SUPER_ADMIN_PHONE` | Initial Super Admin Phone | `+919876543210` |
| `RATE_LIMIT_WINDOW_MS` | Rate limiting sliding window in ms | `900000` (15 mins) |
| `RATE_LIMIT_MAX_REQUESTS`| Max requests per sliding window | `1000` |
| `UPLOAD_DIR` | Directory where document files are saved | `./uploads` |
| `MAX_FILE_SIZE_MB` | Maximum allowed file upload size | `10` |
| `LOG_LEVEL` | Winston logging level | `info` |

---

## Frontend Environment Variables (Passed via `--dart-define`)

| Variable Name | Description | Default Value |
|---|---|---|
| `API_BASE_URL` | Base REST API URL of the backend | `http://localhost:5000/api/v1` |
