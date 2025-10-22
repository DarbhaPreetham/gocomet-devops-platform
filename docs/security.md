# GoCommet DevOps Platform - Security Implementation

## 🔐 Security Architecture Overview

The GoCommet DevOps Platform implements a comprehensive security strategy covering secrets management, network isolation, data encryption, and access control.

## 🛡️ Security Components

### 1. Secrets Management with HashiCorp Vault

#### Vault Configuration
```hcl
# platform/vault/config/vault.hcl
storage "file" {
  path = "/vault/data"
}

listener "tcp" {
  address = "0.0.0.0:8200"
  tls_disable = 1  # Development only
}

api_addr = "http://0.0.0.0:8200"
ui = true
disable_mlock = true
```

#### Secret Storage Strategy
- **Database Credentials**: Encrypted storage of all database passwords
- **API Keys**: Secure storage of external service keys
- **Certificates**: SSL/TLS certificate management
- **Tokens**: JWT signing keys and session tokens

#### Secret Rotation
```bash
# Rotate database password
vault kv put secret/database/postgres password="new-secure-password"

# Rotate API keys
vault kv put secret/applications/sales-api api_key="new-api-key"

# Update application secrets
docker-compose restart sales-api reporting-api
```

### 2. Network Security

#### Network Isolation
```yaml
# Docker network configuration
networks:
  gocomet-platform:
    driver: bridge
    ipam:
      config:
        - subnet: 172.20.0.0/16
```

#### Service Communication
- **Internal Networks**: Services communicate through isolated Docker networks
- **No External Access**: Databases not exposed to host network
- **Reverse Proxy**: Nginx handles external traffic routing

#### Firewall Rules
```bash
# Allow only necessary ports
ufw allow 80/tcp   # HTTP
ufw allow 443/tcp  # HTTPS
ufw allow 22/tcp    # SSH
ufw deny 3306/tcp  # MySQL
ufw deny 5432/tcp  # PostgreSQL
ufw deny 27017/tcp # MongoDB
```

### 3. Data Encryption

#### Database Encryption
- **PostgreSQL**: SSL connections with certificate validation
- **MySQL**: SSL/TLS encryption for data in transit
- **MongoDB**: TLS encryption for network communication

#### Application Data
- **Environment Variables**: Sensitive data stored in Vault
- **API Communications**: HTTPS for all external communications
- **File Storage**: Encrypted volumes for persistent data

### 4. Access Control

#### User Authentication
```javascript
// JWT-based authentication
const jwt = require('jsonwebtoken');
const token = jwt.sign(
  { userId: user.id, role: user.role },
  process.env.JWT_SECRET,
  { expiresIn: '24h' }
);
```

#### Role-Based Access Control (RBAC)
- **Admin**: Full platform access
- **Developer**: Application deployment and management
- **Viewer**: Read-only access to monitoring

#### API Security
```javascript
// Rate limiting
const rateLimit = require('express-rate-limit');
const limiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 100 // limit each IP to 100 requests per windowMs
});
app.use(limiter);

// Security headers
app.use(helmet());
```

## 🔒 Security Implementation Details

### 1. Container Security

#### Non-Root Users
```dockerfile
# Create non-root user
RUN addgroup -g 1001 -S nodejs
RUN adduser -S nodejs -u 1001
RUN chown -R nodejs:nodejs /app
USER nodejs
```

#### Security Scanning
```yaml
# GitHub Actions security scan
- name: Run Trivy vulnerability scanner
  uses: aquasec/trivy-action@master
  with:
    scan-type: 'fs'
    scan-ref: '.'
    format: 'sarif'
    output: 'trivy-results.sarif'
```

#### Image Hardening
- **Minimal Base Images**: Alpine Linux for reduced attack surface
- **No Package Managers**: Remove apt/yum after installation
- **Read-Only Filesystems**: Where possible
- **Security Updates**: Regular base image updates

### 2. Database Security

#### PostgreSQL Security
```sql
-- Create application user with limited privileges
CREATE USER sales_user WITH PASSWORD 'secure_password';
GRANT CONNECT ON DATABASE sales_db TO sales_user;
GRANT USAGE ON SCHEMA public TO sales_user;
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO sales_user;
```

#### MySQL Security
```sql
-- Create WordPress user with limited privileges
CREATE USER 'wordpress_user'@'%' IDENTIFIED BY 'secure_password';
GRANT SELECT, INSERT, UPDATE, DELETE ON wordpress_db.* TO 'wordpress_user'@'%';
FLUSH PRIVILEGES;
```

#### MongoDB Security
```javascript
// Enable authentication
use admin
db.createUser({
  user: "admin",
  pwd: "secure_password",
  roles: ["userAdminAnyDatabase", "dbAdminAnyDatabase", "readWriteAnyDatabase"]
});
```

### 3. Application Security

#### Input Validation
```javascript
// Express.js input validation
const { body, validationResult } = require('express-validator');

app.post('/api/sales', [
  body('amount').isNumeric().withMessage('Amount must be numeric'),
  body('product_name').isLength({ min: 1 }).withMessage('Product name required')
], (req, res) => {
  const errors = validationResult(req);
  if (!errors.isEmpty()) {
    return res.status(400).json({ errors: errors.array() });
  }
  // Process request
});
```

#### SQL Injection Prevention
```javascript
// Parameterized queries
const query = 'SELECT * FROM sales WHERE product_name = $1';
const result = await pool.query(query, [productName]);
```

#### XSS Protection
```javascript
// Helmet.js security headers
app.use(helmet({
  contentSecurityPolicy: {
    directives: {
      defaultSrc: ["'self'"],
      styleSrc: ["'self'", "'unsafe-inline'"],
      scriptSrc: ["'self'"],
      imgSrc: ["'self'", "data:", "https:"]
    }
  }
}));
```

### 4. Monitoring and Alerting

#### Security Monitoring
```yaml
# Prometheus security metrics
- job_name: 'security-events'
  static_configs:
    - targets: ['vault:8200']
  metrics_path: '/v1/sys/metrics'
```

#### Log Analysis
```bash
# Security event monitoring
docker-compose logs -f | grep -E "(ERROR|WARN|SECURITY|AUTH|LOGIN)"
```

#### Alert Rules
```yaml
# Prometheus alerting rules
groups:
  - name: security
    rules:
      - alert: HighErrorRate
        expr: rate(http_requests_total{status=~"5.."}[5m]) > 0.1
        for: 5m
        labels:
          severity: warning
        annotations:
          summary: "High error rate detected"
```

## 🔐 Secret Management Workflow

### 1. Secret Storage
```bash
# Store database credentials
vault kv put secret/database/postgres \
  username="sales_user" \
  password="secure_password" \
  host="postgres" \
  port="5432" \
  database="sales_db"

# Store API keys
vault kv put secret/applications/sales-api \
  jwt_secret="your-jwt-secret" \
  api_key="your-api-key"
```

### 2. Secret Retrieval
```javascript
// Application secret retrieval
const vault = require('node-vault')({
  apiVersion: 'v1',
  endpoint: process.env.VAULT_ADDR,
  token: process.env.VAULT_TOKEN
});

const dbCredentials = await vault.read('secret/database/postgres');
const connectionString = `postgresql://${dbCredentials.data.username}:${dbCredentials.data.password}@${dbCredentials.data.host}:${dbCredentials.data.port}/${dbCredentials.data.database}`;
```

### 3. Secret Rotation
```bash
# Automated secret rotation script
#!/bin/bash
# Rotate database password
NEW_PASSWORD=$(openssl rand -base64 32)
vault kv put secret/database/postgres password="$NEW_PASSWORD"

# Update application configuration
docker-compose exec postgres psql -U postgres -c "ALTER USER sales_user PASSWORD '$NEW_PASSWORD';"

# Restart applications
docker-compose restart sales-api
```

## 🚨 Security Incident Response

### 1. Detection
- **Automated Monitoring**: Prometheus alerts for suspicious activity
- **Log Analysis**: Centralized logging with ELK stack
- **Vulnerability Scanning**: Regular container image scans

### 2. Response Procedures
```bash
# Immediate response
docker-compose down                    # Stop all services
docker-compose logs > incident.log     # Capture logs
docker-compose exec vault vault audit list  # Check Vault audit logs

# Investigation
docker-compose exec postgres psql -U sales_user -d sales_db -c "SELECT * FROM pg_stat_activity;"
docker-compose exec mysql mysql -u wordpress_user -p -e "SHOW PROCESSLIST;"
```

### 3. Recovery
```bash
# Restore from backup
docker-compose exec postgres psql -U sales_user -d sales_db < backup_file.sql

# Rotate all secrets
./scripts/rotate-secrets.sh

# Restart with new configuration
docker-compose up -d
```

## 📋 Security Checklist

### Pre-Deployment
- [ ] All default passwords changed
- [ ] SSL certificates configured
- [ ] Firewall rules applied
- [ ] Security scanning completed
- [ ] Backup procedures tested

### Post-Deployment
- [ ] Security monitoring active
- [ ] Log aggregation working
- [ ] Alert notifications configured
- [ ] Incident response plan ready
- [ ] Regular security updates scheduled

### Ongoing Security
- [ ] Weekly vulnerability scans
- [ ] Monthly security reviews
- [ ] Quarterly penetration testing
- [ ] Annual security audit
- [ ] Continuous monitoring

## �� Security Tools Integration

### 1. Vulnerability Scanning
```yaml
# Trivy configuration
trivy:
  image: aquasec/trivy:latest
  commands:
    - image: sales-api:latest
    - image: reporting-api:latest
    - image: wordpress:latest
```

### 2. Security Headers
```nginx
# Nginx security headers
add_header X-Frame-Options "SAMEORIGIN" always;
add_header X-Content-Type-Options "nosniff" always;
add_header X-XSS-Protection "1; mode=block" always;
add_header Referrer-Policy "no-referrer-when-downgrade" always;
add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;
```

### 3. Access Logging
```nginx
# Detailed access logging
log_format security '$remote_addr - $remote_user [$time_local] '
                   '"$request" $status $body_bytes_sent '
                   '"$http_referer" "$http_user_agent" '
                   '$request_time $upstream_response_time';

access_log /var/log/nginx/security.log security;
```

## 🎯 Security Best Practices

### 1. Development
- Use parameterized queries
- Validate all inputs
- Implement proper error handling
- Use HTTPS everywhere
- Regular dependency updates

### 2. Operations
- Regular security updates
- Monitor access logs
- Implement least privilege
- Regular backup testing
- Incident response planning

### 3. Monitoring
- Real-time security alerts
- Regular vulnerability assessments
- Log analysis and correlation
- Performance monitoring
- Compliance reporting
