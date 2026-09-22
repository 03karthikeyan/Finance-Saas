# Production Deployment Guide

## 1. Production Architecture Overview
```
Clients (Web/Android)  -->  Nginx / Cloudflare (SSL & Reverse Proxy)  -->  Node.js API (PM2 Cluster)  -->  MongoDB Atlas (Replica Set)
```

---

## 2. Backend Deployment

### A. Environment Configuration
Create a production `.env` on your server:
```env
NODE_ENV=production
PORT=5000
API_PREFIX=/api/v1
CLIENT_URL=https://app.financesaas.com
MONGODB_URI=mongodb+srv://<user>:<password>@cluster.mongodb.net/finance_saas_production?retryWrites=true&w=majority
JWT_SECRET=<generated-64-character-secret>
JWT_REFRESH_SECRET=<generated-64-character-refresh-secret>
```

### B. Process Management with PM2
Install PM2 globally and start the application in cluster mode:
```bash
npm install -g pm2
pm2 start src/server.js --name "finance-saas-api" -i max
pm2 save
pm2 startup
```

### C. Nginx Reverse Proxy Configuration
```nginx
server {
    listen 80;
    server_name api.financesaas.com;
    return 301 https://$host$request_uri;
}

server {
    listen 443 ssl http2;
    server_name api.financesaas.com;

    ssl_certificate /etc/letsencrypt/live/api.financesaas.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/api.financesaas.com/privkey.pem;

    location / {
        proxy_pass http://127.0.0.1:5000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_cache_bypass $http_upgrade;
    }
}
```

---

## 3. Frontend Flutter Web Deployment

1. **Build Production Web Bundle**:
```bash
cd frontend
flutter build web --release --dart-define=API_BASE_URL=https://api.financesaas.com/api/v1
```
The output directory will be in `frontend/build/web`.

2. **Deploy to Hosting Provider (Vercel / Netlify / Nginx / S3 + CloudFront)**:
Deploy the contents of `build/web` as static SPA hosting. Ensure your hosting server redirects all 404 paths to `index.html` for routing.

---

## 4. Frontend Flutter Android Deployment

1. **Build Release APK**:
```bash
flutter build apk --release --dart-define=API_BASE_URL=https://api.financesaas.com/api/v1
```

2. **Build Release App Bundle (AAB for Google Play Store)**:
```bash
flutter build appbundle --release --dart-define=API_BASE_URL=https://api.financesaas.com/api/v1
```
