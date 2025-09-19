// server.js - SUPABASE VERSION
require('dotenv').config()

const express = require('express');
const cors = require('cors');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const XLSX = require('xlsx');
const path = require('path');
const fs = require('fs');
const { createClient } = require('@supabase/supabase-js');

const app = express();
const PORT = process.env.PORT || 3000;

// Middleware
app.use(cors());
app.use(express.json());

const JWT_SECRET = process.env.JWT_SECRET || 'your-secret-key-change-this-in-production';

// Supabase Configuration
const supabaseUrl = process.env.SUPABASE_URL;
const supabaseKey = process.env.SUPABASE_KEY;

if (!supabaseUrl || !supabaseKey) {
    console.error('❌ Missing Supabase credentials');
    process.exit(1);
}

const supabase = createClient(supabaseUrl, supabaseKey);
console.log('✅ Supabase Client Connected');

// Health Check
app.get('/api/health', async (req, res) => {
    try {
        const { count } = await supabase
            .from('products')
            .select('*', { count: 'exact', head: true });

        res.json({
            status: 'OK',
            message: 'Server running with Supabase',
            productsInDatabase: count || 0,
            timestamp: new Date(),
            server: {
                port: PORT,
                environment: process.env.NODE_ENV || 'development',
                database: 'Supabase PostgreSQL'
            }
        });
    } catch (error) {
        res.status(500).json({
            status: 'ERROR',
            message: 'Database error',
            error: error.message
        });
    }
});

// Auth Routes (simplified)
app.post('/api/auth/login', async (req, res) => {
    try {
        const { email, password } = req.body;

        if (!email || !password) {
            return res.status(400).json({ error: 'Email and password required' });
        }

        const { data: user, error } = await supabase
            .from('users')
            .select('*')
            .eq('email', email.toLowerCase())
            .single();

        if (error || !user) {
            return res.status(401).json({ error: 'Invalid credentials' });
        }

        const isValidPassword = await bcrypt.compare(password, user.password);
        if (!isValidPassword) {
            return res.status(401).json({ error: 'Invalid credentials' });
        }

        const token = jwt.sign(
            { id: user.id, email: user.email, role: user.role },
            JWT_SECRET,
            { expiresIn: '7d' }
        );

        res.json({
            message: 'Login successful',
            user: {
                id: user.id,
                name: user.name,
                email: user.email,
                role: user.role,
                token
            }
        });
    } catch (error) {
        res.status(500).json({ error: 'Server error' });
    }
});

// Product Search
app.get('/api/products/search', async (req, res) => {
    try {
        const { id } = req.query;

        if (!id) {
            return res.status(400).json({ error: 'Product ID required' });
        }

        const { data: product, error } = await supabase
            .from('products')
            .select('*')
            .eq('product_id', id.trim())
            .single();

        if (error || !product) {
            return res.status(404).json({
                error: 'Product not found',
                searchedId: id
            });
        }

        res.json({
            product: {
                id: product.product_id,
                name: product.name,
                price: product.price,
                original_price: product.original_price,
                current_price: product.current_price,
                category: product.category,
                warehouse_name: product.warehouse_name || '',
                sector: product.sector || '',
                current_quantity: product.current_quantity || 0,
                discount_amount: product.discount_amount || 0,
                discount_percentage: product.discount_percentage || 0
            },
            message: 'Product found successfully'
        });
    } catch (error) {
        res.status(500).json({ error: 'Server error' });
    }
});

// Start server
app.listen(PORT, '0.0.0.0', () => {
    console.log(`🚀 Server running on port ${PORT}`);
    console.log(`🗄️ Database: Supabase PostgreSQL`);
});
