const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const rateLimit = require('express-rate-limit');
const { Pool } = require('pg');
require('dotenv').config();

const app = express();
const PORT = process.env.PORT || 3000;

// Database connection
const pool = new Pool({
  connectionString: process.env.DATABASE_URL || 'postgresql://sales_user:sales_password@postgres:5432/sales_db',
  ssl: process.env.NODE_ENV === 'production' ? { rejectUnauthorized: false } : false
});

// Middleware
app.use(helmet());
app.use(cors());
app.use(express.json());

// Rate limiting
const limiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 100 // limit each IP to 100 requests per windowMs
});
app.use(limiter);

// Health check endpoint
app.get('/health', (req, res) => {
  res.json({ status: 'OK', timestamp: new Date().toISOString() });
});

// Sales data endpoints
app.get('/api/sales', async (req, res) => {
  try {
    const { period = '30d' } = req.query;
    let query = `
      SELECT 
        DATE(created_at) as date,
        SUM(amount) as total_sales,
        COUNT(*) as transaction_count
      FROM sales 
      WHERE created_at >= NOW() - INTERVAL '${period}'
      GROUP BY DATE(created_at)
      ORDER BY date DESC
    `;
    
    const result = await pool.query(query);
    res.json(result.rows);
  } catch (error) {
    console.error('Error fetching sales data:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

app.get('/api/sales/summary', async (req, res) => {
  try {
    const query = `
      SELECT 
        SUM(amount) as total_revenue,
        COUNT(*) as total_transactions,
        AVG(amount) as average_transaction,
        MAX(amount) as highest_sale
      FROM sales 
      WHERE created_at >= NOW() - INTERVAL '30 days'
    `;
    
    const result = await pool.query(query);
    res.json(result.rows[0]);
  } catch (error) {
    console.error('Error fetching sales summary:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

app.get('/api/sales/products', async (req, res) => {
  try {
    const query = `
      SELECT 
        product_name,
        SUM(quantity) as total_sold,
        SUM(amount) as total_revenue
      FROM sales 
      WHERE created_at >= NOW() - INTERVAL '30 days'
      GROUP BY product_name
      ORDER BY total_revenue DESC
      LIMIT 10
    `;
    
    const result = await pool.query(query);
    res.json(result.rows);
  } catch (error) {
    console.error('Error fetching product data:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// Initialize database
async function initializeDatabase() {
  try {
    // Create sales table if it doesn't exist
    await pool.query(`
      CREATE TABLE IF NOT EXISTS sales (
        id SERIAL PRIMARY KEY,
        product_name VARCHAR(255) NOT NULL,
        amount DECIMAL(10,2) NOT NULL,
        quantity INTEGER NOT NULL,
        customer_name VARCHAR(255),
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      )
    `);

    // Insert sample data if table is empty
    const countResult = await pool.query('SELECT COUNT(*) FROM sales');
    if (parseInt(countResult.rows[0].count) === 0) {
      const sampleData = [
        ['Laptop Pro', 1299.99, 1, 'John Doe'],
        ['Wireless Mouse', 29.99, 2, 'Jane Smith'],
        ['Monitor 4K', 399.99, 1, 'Bob Johnson'],
        ['Keyboard Mechanical', 149.99, 1, 'Alice Brown'],
        ['Webcam HD', 79.99, 1, 'Charlie Wilson']
      ];

      for (const [product, amount, quantity, customer] of sampleData) {
        await pool.query(
          'INSERT INTO sales (product_name, amount, quantity, customer_name) VALUES ($1, $2, $3, $4)',
          [product, amount, quantity, customer]
        );
      }
      console.log('Sample data inserted successfully');
    }
  } catch (error) {
    console.error('Error initializing database:', error);
  }
}

// Start server
app.listen(PORT, async () => {
  console.log(`Sales Dashboard API running on port ${PORT}`);
  await initializeDatabase();
});

module.exports = app;
