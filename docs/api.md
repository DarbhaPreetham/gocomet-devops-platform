# GoCommet DevOps Platform - API Documentation

## 📚 API Endpoints

### Sales Dashboard API
**Base URL**: http://localhost:3001

#### Health Check
```http
GET /health
```

#### Sales Data
```http
GET /api/sales?period=30d
GET /api/sales/summary
GET /api/sales/products
```

### Reporting API
**Base URL**: http://localhost:5000

#### Health Check
```http
GET /health
```

#### Reports
```http
GET /api/reports
GET /api/reports/{id}
POST /api/reports
PUT /api/reports/{id}
DELETE /api/reports/{id}
GET /api/reports/stats
```

### Vault API
**Base URL**: http://localhost:8200

#### Health Check
```http
GET /v1/sys/health
```

#### Secrets
```http
GET /v1/secret/{path}
POST /v1/secret/{path}
PUT /v1/secret/{path}
DELETE /v1/secret/{path}
```
