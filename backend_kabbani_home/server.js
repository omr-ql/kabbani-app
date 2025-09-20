// server.js - COMPLETE SUPABASE VERSION
require('dotenv').config()

const express = require('express');
const cors = require('cors');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
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

app.use(express.static('public'));
if (!supabaseUrl || !supabaseKey) {
    console.error('❌ Missing Supabase credentials');
    process.exit(1);
}

const supabase = createClient(supabaseUrl, supabaseKey);
console.log('✅ Supabase Client Connected');

// ============ ROUTES YOUR FLUTTER APP NEEDS ============

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

const authenticateToken = (req, res, next) => {
    const authHeader = req.headers['authorization'];
    const token = authHeader && authHeader.split(' ')[1];

    if (!token) {
        return res.status(401).json({ error: 'Access token required' });
    }

    jwt.verify(token, JWT_SECRET, (err, user) => {
        if (err) {
            return res.status(403).json({ error: 'Invalid or expired token' });
        }
        req.user = user;
        next();
    });
};

const requireAdmin = async (req, res, next) => {
    try {
        const { data: user, error } = await supabase
            .from('users')
            .select('role')
            .eq('id', req.user.id)
            .single();

        if (error || !user || user.role !== 'admin') {
            return res.status(403).json({ 
                error: 'Admin access required. Only administrators can perform this action.' 
            });
        }
        next();
    } catch (error) {
        return res.status(500).json({ error: 'Server error' });
    }
};

// Auth Routes
app.post('/api/auth/signup', async (req, res) => {
    try {
        const { name, email, password } = req.body;
        
        if (!name || !email || !password) {
            return res.status(400).json({ error: 'All fields are required' });
        }

        // Check if user exists
        const { data: existingUser } = await supabase
            .from('users')
            .select('id')
            .eq('email', email.toLowerCase())
            .single();

        if (existingUser) {
            return res.status(400).json({ error: 'User already exists' });
        }

        // Hash password and create user
        const hashedPassword = await bcrypt.hash(password, 10);
        
        const { data: user, error } = await supabase
            .from('users')
            .insert({
                name: name.trim(),
                email: email.toLowerCase().trim(),
                password: hashedPassword,
                role: 'user'
            })
            .select()
            .single();

        if (error) throw error;

        const token = jwt.sign(
            { id: user.id, email: user.email, role: user.role },
            JWT_SECRET,
            { expiresIn: '7d' }
        );

        res.status(201).json({
            message: 'User created successfully',
            user: {
                id: user.id,
                name: user.name,
                email: user.email,
                role: user.role,
                token
            }
        });
    } catch (error) {
        res.status(500).json({ error: 'Server error: ' + error.message });
    }
});

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


app.get('/product', (req, res) => {
    res.sendFile(path.join(__dirname, 'public', 'product.html'));
});

// Product Search (Main endpoint for QR scanner)
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
                original_price: product.original_price || product.price,
                current_price: product.current_price || product.price,
                category: product.category || 'General',
                warehouse_name: product.warehouse_name || '',
                sector: product.sector || '',
                current_quantity: product.current_quantity || 0,
                discount_amount: product.discount_amount || 0,
                discount_percentage: product.discount_percentage || 0,
                total_value: product.total_value || 0
            },
            message: 'Product found successfully'
        });
    } catch (error) {
        res.status(500).json({ error: 'Server error: ' + error.message });
    }
});

// Get all products
app.get('/api/products', async (req, res) => {
    try {
        const { limit = 100, offset = 0 } = req.query;
        
        const { data: products, error } = await supabase
            .from('products')
            .select('*')
            .range(parseInt(offset), parseInt(offset) + parseInt(limit) - 1)
            .order('name');

        if (error) throw error;

        res.json({
            products: products.map(p => ({
                id: p.product_id,
                name: p.name,
                price: p.price,
                original_price: p.original_price || p.price,
                current_price: p.current_price || p.price,
                category: p.category,
                warehouse_name: p.warehouse_name,
                sector: p.sector,
                current_quantity: p.current_quantity || 0
            })),
            total: products.length
        });
    } catch (error) {
        res.status(500).json({ error: 'Server error: ' + error.message });
    }
});

// Get categories
app.get('/api/categories', async (req, res) => {
    try {
        const { data, error } = await supabase
            .from('products')
            .select('category')
            .not('category', 'is', null);

        if (error) throw error;

        const categories = [...new Set(data.map(p => p.category).filter(Boolean))];
        res.json({ categories, total: categories.length });
    } catch (error) {
        res.status(500).json({ error: 'Server error: ' + error.message });
    }
});

// Search products by name
app.get('/api/products/search-by-name', async (req, res) => {
    try {
        const { q, category, sort } = req.query;
        
        let query = supabase.from('products').select('*');
        
        if (q) {
            query = query.or(`name.ilike.%${q}%,product_id.ilike.%${q}%`);
        }
        
        if (category && category !== 'All') {
            query = query.eq('category', category);
        }

        const { data: products, error } = await query;
        if (error) throw error;

        // Apply sorting
        if (sort === 'name') {
            products.sort((a, b) => a.name.localeCompare(b.name));
        } else if (sort === 'price_low') {
            products.sort((a, b) => (a.current_price || a.price) - (b.current_price || b.price));
        }

        res.json({
            products: products.map(p => ({
                id: p.product_id,
                name: p.name,
                price: p.price,
                original_price: p.original_price || p.price,
                current_price: p.current_price || p.price,
                category: p.category,
                warehouse_name: p.warehouse_name,
                sector: p.sector,
                current_quantity: p.current_quantity || 0
            })),
            total: products.length
        });
    } catch (error) {
        res.status(500).json({ error: 'Server error: ' + error.message });
    }
});

app.put('/api/admin/products/:productId/quantity', async (req, res) => {
    try {
        console.log('🔧 Admin quantity update request received');
        
        // Get token from Authorization header
        const authHeader = req.headers['authorization'];
        const token = authHeader && authHeader.split(' ')[1];

        if (!token) {
            console.log('❌ No token provided');
            return res.status(401).json({ error: 'Access token required' });
        }

        // Verify JWT token
        let decoded;
        try {
            decoded = jwt.verify(token, JWT_SECRET);
            console.log('✅ Token verified for user:', decoded.email);
        } catch (error) {
            console.log('❌ Invalid token:', error.message);
            return res.status(403).json({ error: 'Invalid token' });
        }

        // Check if user is admin
        const { data: user, error: userError } = await supabase
            .from('users')
            .select('role')
            .eq('id', decoded.id)
            .single();

        if (userError || !user || user.role !== 'admin') {
            console.log('❌ User is not admin:', user?.role);
            return res.status(403).json({ error: 'Admin access required' });
        }

        console.log('✅ Admin access confirmed');

        // Get product ID and new quantity
        const { productId } = req.params;
        const { quantity } = req.body;

        console.log('📦 Updating product:', productId, 'to quantity:', quantity);

        if (quantity === undefined || quantity < 0) {
            return res.status(400).json({ error: 'Valid quantity required (must be >= 0)' });
        }

        // Update the product quantity in Supabase
        const { data: updatedProduct, error: updateError } = await supabase
            .from('products')
            .update({ 
                current_quantity: parseInt(quantity),
                total_value: parseInt(quantity) * 1833.3333 // You can calculate this based on price
            })
            .eq('product_id', productId)
            .select()
            .single();

        if (updateError) {
            console.log('❌ Database update error:', updateError);
            return res.status(500).json({ error: 'Failed to update product' });
        }

        if (!updatedProduct) {
            console.log('❌ Product not found:', productId);
            return res.status(404).json({ error: 'Product not found' });
        }

        console.log('✅ Product quantity updated successfully');

        res.json({
            success: true,
            message: 'Quantity updated successfully',
            product: {
                id: updatedProduct.product_id,
                name: updatedProduct.name,
                old_quantity: 'previous', // You can track this if needed
                new_quantity: updatedProduct.current_quantity,
                updated_by: decoded.email
            }
        });

    } catch (error) {
        console.error('❌ Update quantity error:', error);
        res.status(500).json({ error: 'Server error: ' + error.message });
    }
});

// Start server
app.listen(PORT, '0.0.0.0', () => {
    console.log(`🚀 Server running on port ${PORT}`);
    console.log(`🗄️ Database: Supabase PostgreSQL`);
    console.log(`📱 Flutter app can connect to: http://192.168.1.4:${PORT}/api`);
});
