// server.js - COMPLETE SUPABASE VERSION WITH RESERVATIONS
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
const supabaseKey = process.env.SUPABASE_SERVICE_KEY || process.env.SUPABASE_KEY;

app.use(express.static('public'));
if (!supabaseUrl || !supabaseKey) {
    console.error('❌ Missing Supabase credentials');
    process.exit(1);
}

const supabase = createClient(supabaseUrl, supabaseKey);
console.log('✅ Supabase Client Connected');

// ============ MIDDLEWARE ============

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

// ============ ROUTES ============

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

// ============ AUTH ROUTES ============

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

// ============ PRODUCT ROUTES ============

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

// Update product quantity (Admin only)
app.put('/api/admin/products/:productId/quantity', authenticateToken, requireAdmin, async (req, res) => {
    try {
        console.log('🔧 Admin quantity update request received');

        const { productId } = req.params;
        const { quantity } = req.body;

        console.log('📦 Updating product:', productId, 'to quantity:', quantity);

        if (quantity === undefined || quantity < 0) {
            return res.status(400).json({ error: 'Valid quantity required (must be >= 0)' });
        }

        // Get current product to calculate total_value
        const { data: currentProduct } = await supabase
            .from('products')
            .select('price')
            .eq('product_id', productId)
            .single();

        // Update the product quantity in Supabase
        const { data: updatedProduct, error: updateError } = await supabase
            .from('products')
            .update({ 
                current_quantity: parseInt(quantity),
                total_value: currentProduct ? parseInt(quantity) * currentProduct.price : 0
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
                new_quantity: updatedProduct.current_quantity,
                updated_by: req.user.email
            }
        });

    } catch (error) {
        console.error('❌ Update quantity error:', error);
        res.status(500).json({ error: 'Server error: ' + error.message });
    }
});

// ============ RESERVATION ROUTES ============

// CREATE RESERVATION
app.post('/api/reservations', authenticateToken, async (req, res) => {
    try {
        console.log('📝 New reservation request from user:', req.user.email);

        const { 
            productId, 
            productName, 
            customerName, 
            customerContact, 
            quantity, 
            pickupDate, 
            notes 
        } = req.body;

        // Validate required fields
        if (!productId || !productName || !customerName || !customerContact || !quantity || !pickupDate) {
            return res.status(400).json({ error: 'All required fields must be provided' });
        }

        if (quantity <= 0) {
            return res.status(400).json({ error: 'Quantity must be greater than 0' });
        }

        // Check if product exists and has enough stock
        const { data: product, error: productError } = await supabase
            .from('products')
            .select('current_quantity, price')
            .eq('product_id', productId)
            .single();

        if (productError || !product) {
            return res.status(404).json({ error: 'Product not found' });
        }

        if (product.current_quantity < quantity) {
            return res.status(400).json({ 
                error: `Insufficient stock. Available: ${product.current_quantity}, Requested: ${quantity}` 
            });
        }

        // Reduce product stock
        const newQuantity = product.current_quantity - quantity;
        const { error: updateError } = await supabase
            .from('products')
            .update({ 
                current_quantity: newQuantity,
                total_value: newQuantity * product.price
            })
            .eq('product_id', productId);

        if (updateError) {
            console.error('❌ Failed to update stock:', updateError);
            return res.status(500).json({ error: 'Failed to update stock' });
        }

        console.log(`📉 Stock reduced: ${product.current_quantity} → ${newQuantity}`);

        // Create reservation
        const { data: reservation, error: reservationError } = await supabase
            .from('reservations')
            .insert({
                product_id: productId,
                product_name: productName,
                customer_id: req.user.id,
                customer_name: customerName,
                customer_contact: customerContact,
                quantity: quantity,
                pickup_date: pickupDate,
                notes: notes || null,
                is_fulfilled: false,
                created_at: new Date().toISOString()
            })
            .select()
            .single();

        if (reservationError) {
            console.error('❌ Failed to create reservation:', reservationError);
            
            // Rollback stock change
            await supabase
                .from('products')
                .update({ 
                    current_quantity: product.current_quantity,
                    total_value: product.current_quantity * product.price
                })
                .eq('product_id', productId);

            return res.status(500).json({ error: 'Failed to create reservation' });
        }

        console.log('✅ Reservation created successfully:', reservation.id);

        // TODO: Send notification to admins here
        // You can add notification logic later

        res.status(201).json({
            success: true,
            message: 'Reservation created successfully',
            data: {
                _id: reservation.id,
                productId: reservation.product_id,
                productName: reservation.product_name,
                customerId: reservation.customer_id,
                customerName: reservation.customer_name,
                customerContact: reservation.customer_contact,
                quantity: reservation.quantity,
                pickupDate: reservation.pickup_date,
                notes: reservation.notes,
                createdAt: reservation.created_at,
                isFulfilled: reservation.is_fulfilled
            }
        });

    } catch (error) {
        console.error('❌ Create reservation error:', error);
        res.status(500).json({ error: 'Server error: ' + error.message });
    }
});

// GET ALL RESERVATIONS (Admin only)
app.get('/api/reservations', authenticateToken, requireAdmin, async (req, res) => {
    try {
        console.log('📋 Admin fetching all reservations');

        const { data: reservations, error } = await supabase
            .from('reservations')
            .select('*')
            .order('created_at', { ascending: false });

        if (error) {
            console.error('❌ Failed to fetch reservations:', error);
            return res.status(500).json({ error: 'Failed to fetch reservations' });
        }

        // Format response
        const formattedReservations = reservations.map(r => ({
            _id: r.id,
            productId: r.product_id,
            productName: r.product_name,
            customerId: r.customer_id,
            customerName: r.customer_name,
            customerContact: r.customer_contact,
            quantity: r.quantity,
            pickupDate: r.pickup_date,
            notes: r.notes,
            createdAt: r.created_at,
            isFulfilled: r.is_fulfilled
        }));

        console.log(`✅ Found ${formattedReservations.length} reservations`);
        res.json(formattedReservations);

    } catch (error) {
        console.error('❌ Get reservations error:', error);
        res.status(500).json({ error: 'Server error: ' + error.message });
    }
});

// GET MY RESERVATIONS (Customer)
app.get('/api/reservations/my', authenticateToken, async (req, res) => {
    try {
        console.log('📋 User fetching their reservations:', req.user.email);

        const { data: reservations, error } = await supabase
            .from('reservations')
            .select('*')
            .eq('customer_id', req.user.id)
            .order('created_at', { ascending: false });

        if (error) {
            console.error('❌ Failed to fetch user reservations:', error);
            return res.status(500).json({ error: 'Failed to fetch reservations' });
        }

        // Format response
        const formattedReservations = reservations.map(r => ({
            _id: r.id,
            productId: r.product_id,
            productName: r.product_name,
            customerId: r.customer_id,
            customerName: r.customer_name,
            customerContact: r.customer_contact,
            quantity: r.quantity,
            pickupDate: r.pickup_date,
            notes: r.notes,
            createdAt: r.created_at,
            isFulfilled: r.is_fulfilled
        }));

        console.log(`✅ Found ${formattedReservations.length} reservations for user`);
        res.json(formattedReservations);

    } catch (error) {
        console.error('❌ Get my reservations error:', error);
        res.status(500).json({ error: 'Server error: ' + error.message });
    }
});

// CANCEL RESERVATION (Restore stock)
app.delete('/api/reservations/:reservationId', authenticateToken, async (req, res) => {
    try {
        const { reservationId } = req.params;
        console.log('🗑️ Cancelling reservation:', reservationId);

        // Get reservation details
        const { data: reservation, error: fetchError } = await supabase
            .from('reservations')
            .select('*')
            .eq('id', reservationId)
            .single();

        if (fetchError || !reservation) {
            return res.status(404).json({ error: 'Reservation not found' });
        }

        // Check if user owns this reservation or is admin
        const { data: user } = await supabase
            .from('users')
            .select('role')
            .eq('id', req.user.id)
            .single();

        if (reservation.customer_id !== req.user.id && user.role !== 'admin') {
            return res.status(403).json({ error: 'Not authorized to cancel this reservation' });
        }

        // Don't allow cancelling fulfilled reservations
        if (reservation.is_fulfilled) {
            return res.status(400).json({ error: 'Cannot cancel fulfilled reservations' });
        }

        // Restore stock
        const { data: product } = await supabase
            .from('products')
            .select('current_quantity, price')
            .eq('product_id', reservation.product_id)
            .single();

        if (product) {
            const newQuantity = product.current_quantity + reservation.quantity;
            await supabase
                .from('products')
                .update({ 
                    current_quantity: newQuantity,
                    total_value: newQuantity * product.price
                })
                .eq('product_id', reservation.product_id);

            console.log(`📈 Stock restored: ${product.current_quantity} → ${newQuantity}`);
        }

        // Delete reservation
        const { error: deleteError } = await supabase
            .from('reservations')
            .delete()
            .eq('id', reservationId);

        if (deleteError) {
            console.error('❌ Failed to delete reservation:', deleteError);
            return res.status(500).json({ error: 'Failed to cancel reservation' });
        }

        console.log('✅ Reservation cancelled successfully');
        res.json({ 
            success: true,
            message: 'Reservation cancelled successfully' 
        });

    } catch (error) {
        console.error('❌ Cancel reservation error:', error);
        res.status(500).json({ error: 'Server error: ' + error.message });
    }
});

// MARK RESERVATION AS FULFILLED (Admin only - Stock NOT restored)
app.patch('/api/reservations/:reservationId/fulfill', authenticateToken, requireAdmin, async (req, res) => {
    try {
        const { reservationId } = req.params;
        console.log('✅ Admin marking reservation as fulfilled:', reservationId);

        // Update reservation status
        const { data: reservation, error } = await supabase
            .from('reservations')
            .update({ is_fulfilled: true })
            .eq('id', reservationId)
            .select()
            .single();

        if (error || !reservation) {
            console.error('❌ Failed to fulfill reservation:', error);
            return res.status(404).json({ error: 'Reservation not found' });
        }

        console.log('✅ Reservation fulfilled successfully');
        
        res.json({
            success: true,
            message: 'Reservation marked as fulfilled',
            reservation: {
                _id: reservation.id,
                isFulfilled: reservation.is_fulfilled
            }
        });

    } catch (error) {
        console.error('❌ Fulfill reservation error:', error);
        res.status(500).json({ error: 'Server error: ' + error.message });
    }
});

// ============ START SERVER ============

app.listen(PORT, '0.0.0.0', () => {
    console.log(`🚀 Server running on port ${PORT}`);
    console.log(`🗄️ Database: Supabase PostgreSQL`);
    console.log(`📱 Flutter app can connect to: http://localhost:${PORT}/api`);
    console.log(`✨ Reservation feature: ENABLED`);
});