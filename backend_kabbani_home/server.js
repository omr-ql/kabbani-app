// server.js - COMPLETE BACKEND FOR FURNITURE INVENTORY
const express = require('express');
const cors = require('cors');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const XLSX = require('xlsx');
const path = require('path');
const fs = require('fs');
const mongoose = require('mongoose');

const app = express();
const PORT = process.env.PORT || 3000;

// Middleware
app.use(cors());
app.use(express.json());

const JWT_SECRET = 'your-secret-key-change-this-in-production';

// MongoDB Connection
const MONGODB_URI = 'mongodb://localhost:27017/home_furnishing';

// Connect to MongoDB
mongoose.connect(MONGODB_URI, {
  useNewUrlParser: true,
  useUnifiedTopology: true,
}).then(() => {
  console.log('✅ MongoDB Connected');
  loadProductsFromExcel(); // Load products after DB connection
}).catch(err => {
  console.error('❌ MongoDB Connection Error:', err);
});

// ============ MONGODB SCHEMAS ============
// User Schema
const userSchema = new mongoose.Schema({
  name: { type: String, required: true },
  email: { type: String, required: true, unique: true },
  password: { type: String, required: true },
  role: { type: String, enum: ['user', 'admin'], default: 'user' }, // Added role field
  createdAt: { type: Date, default: Date.now }
});

// Updated Product Schema to match your furniture inventory
const productSchema = new mongoose.Schema({
  id: { type: String, required: true, unique: true },
  productId: { type: String, required: true }, // Maps to ID column
  name: { type: String, required: true }, // Maps to اسم الصنف
  sector: { type: String }, // Maps to القطاع
  warehouseName: { type: String }, // Maps to اسم المخزن
  currentQuantity: { type: Number, default: 0 }, // Maps to الكمية الحالية للمخازن
  currentPrice: { type: Number, default: 0 }, // Maps to السعر الحالي
  price: { type: Number, required: true }, // Maps to السعر
  originalPrice: { type: Number, default: 0 }, // Maps to قبل الخصم
  category: { type: String, default: 'General' },
  
  // Calculated fields
  discountAmount: { type: Number, default: 0 },
  discountPercentage: { type: Number, default: 0 },
  totalValue: { type: Number, default: 0 },
  
  // Metadata
  importDate: { type: Date, default: Date.now },
  lastUpdated: { type: Date, default: Date.now }
});

// Create Models
const User = mongoose.model('User', userSchema);
const Product = mongoose.model('Product', productSchema);

async function createAdminAccount() {
  try {
    // Check if admin already exists
    const existingAdmin = await User.findOne({ role: 'admin' });
    if (existingAdmin) {
      console.log('✅ Admin account already exists:', existingAdmin.email);
      return;
    }

    // Create admin account
    const adminPassword = 'Admin@123'; // You can change this password
    const hashedPassword = await bcrypt.hash(adminPassword, 10);
    
    const admin = new User({
      name: 'Administrator',
      email: 'admin@kabbani.com', // You can change this email
      password: hashedPassword,
      role: 'admin'
    });

    await admin.save();
    console.log('🔐 Admin account created successfully!');
    console.log('📧 Email: admin@kabbani.com');
    console.log('🔑 Password: Admin@123');
    console.log('⚠️  Please change the default password after first login!');
    
  } catch (error) {
    console.error('❌ Error creating admin account:', error);
  }
}

// Call this after MongoDB connection
mongoose.connect(MONGODB_URI, {
  useNewUrlParser: true,
  useUnifiedTopology: true,
}).then(() => {
  console.log('✅ MongoDB Connected');
  loadProductsFromExcel();
  createAdminAccount(); // Create admin account on server start
}).catch(err => {
  console.error('❌ MongoDB Connection Error:', err);
});

// ============ LOAD PRODUCTS FROM EXCEL ============
async function loadProductsFromExcel() {
  try {
    // Check if products already exist
    const count = await Product.countDocuments();
    if (count > 0) {
      console.log(`📊 ${count} products already in database`);
      return;
    }

    // Look for your actual Excel file - UPDATE THIS WITH YOUR EXACT FILENAME
    const possibleFilenames = [
      'كميات المفروشات في الصعيد 28.8.xlsx',
      'furniture_data.xlsx',
      'products.xlsx',
      'furniture_inventory.xlsx'
    ];
    
    let filePath = null;
    for (const filename of possibleFilenames) {
      const testPath = path.join(__dirname, filename);
      if (fs.existsSync(testPath)) {
        filePath = testPath;
        console.log(`📁 Found Excel file: ${filename}`);
        break;
      }
    }
    
    if (filePath) {
      console.log('📖 Loading products from Excel file...');
      
      const workbook = XLSX.readFile(filePath);
      const sheetName = workbook.SheetNames[0];
      const sheet = workbook.Sheets[sheetName];
      const data = XLSX.utils.sheet_to_json(sheet);
      
      console.log(`📋 Found ${data.length} rows in Excel file`);
      console.log('📋 Sample row:', data[0]); // Log first row to see column names
      
      let successCount = 0;
      let errorCount = 0;
      
      // Process and save each product
      for (const [index, row] of data.entries()) {
        try {
          // Helper function to safely parse numbers
          const parseNumber = (value) => {
            if (value == null || value === '') return 0;
            const parsed = parseFloat(value);
            return isNaN(parsed) ? 0 : parsed;
          };
          
          // Helper function to safely get string values
          const getString = (value) => {
            if (value == null) return '';
            return String(value).trim();
          };
          
          // Extract data using the actual column names from your Excel file
          const productData = {
            id: `${getString(row['ID'])}_${index}`, // Unique ID for MongoDB
            productId: getString(row['ID']),
            name: getString(row['اسم الصنف']),
            sector: getString(row['القطاع']),
            warehouseName: getString(row['اسم المخزن']),
            currentQuantity: parseInt(row['الكمية الحالية للمخازن']) || 0,
            currentPrice: parseNumber(row['السعر الحالي']),
            price: parseNumber(row['السعر']),
            originalPrice: parseNumber(row['قبل الخصم']),
            category: determineCategoryFromId(getString(row['ID'])),
            importDate: new Date(),
            lastUpdated: new Date()
          };
          
          // Calculate discount fields
          if (productData.originalPrice > 0 && productData.price > 0) {
            productData.discountAmount = productData.originalPrice - productData.price;
            productData.discountPercentage = (productData.discountAmount / productData.originalPrice) * 100;
          }
          
          // Calculate total value
          productData.totalValue = productData.currentQuantity * productData.currentPrice;
          
          // Create and save product
          const product = new Product(productData);
          await product.save();
          successCount++;
          
          // Log progress every 100 products
          if (successCount % 100 === 0) {
            console.log(`✅ Processed ${successCount} products...`);
          }
          
        } catch (err) {
          errorCount++;
          if (err.code !== 11000) { // Ignore duplicate key errors
            console.error(`❌ Error saving product ${index}:`, err.message);
          }
        }
      }
      
      console.log(`\n🎉 Import Summary:`);
      console.log(`✅ Successfully imported: ${successCount} products`);
      console.log(`❌ Errors encountered: ${errorCount}`);
      console.log(`📊 Total in database: ${await Product.countDocuments()}`);
      
    } else {
      console.log('⚠️ Excel file not found, adding sample products...');
      await addSampleProducts();
    }
  } catch (error) {
    console.error('❌ Error loading products:', error);
    await addSampleProducts();
  }
}

// ============ MIDDLEWARE FOR ADMIN AUTHENTICATION ============
const authenticateToken = (req, res, next) => {
  const authHeader = req.headers['authorization'];
  const token = authHeader && authHeader.split(' ')[1]; // Bearer TOKEN

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
    const user = await User.findById(req.user.id);
    if (!user || user.role !== 'admin') {
      return res.status(403).json({ 
        error: 'Admin access required. Only administrators can perform this action.' 
      });
    }
    next();
  } catch (error) {
    return res.status(500).json({ error: 'Server error' });
  }
};

// Add sample products if Excel file is not found
async function addSampleProducts() {
  const sampleProducts = [
    {
      id: '250-10-0001-01-00006_0',
      productId: '250-10-0001-01-00006',
      name: 'طقم جلوس ميموري',
      sector: 'قطاع الصعيد',
      warehouseName: 'الفيوم - مفروشات ومراتب',
      currentQuantity: 2,
      currentPrice: 868.421,
      price: 989.999,
      originalPrice: 1164.706,
      category: 'Furniture',
      discountAmount: 174.707,
      discountPercentage: 15.0,
      totalValue: 1736.842
    },
    {
      id: '250-10-0001-01-00007_1',
      productId: '250-10-0001-01-00007',
      name: 'طقم صدفية 4ق محلي',
      sector: 'قطاع الصعيد',
      warehouseName: 'المنيا - مفروشات ومراتب',
      currentQuantity: 1,
      currentPrice: 592.11,
      price: 675.00,
      originalPrice: 794.12,
      category: 'Furniture',
      discountAmount: 119.12,
      discountPercentage: 15.0,
      totalValue: 592.11
    },
    {
      id: '250-02-0001-01-00008_2',
      productId: '250-02-0001-01-00008',
      name: 'سجادة فارسية كلاسيك',
      sector: 'قطاع الصعيد',
      warehouseName: 'أسيوط - سجاد ومفروشات',
      currentQuantity: 5,
      currentPrice: 1200.00,
      price: 1350.00,
      originalPrice: 1500.00,
      category: 'Carpets',
      discountAmount: 150.00,
      discountPercentage: 10.0,
      totalValue: 6000.00
    }
  ];

  for (const productData of sampleProducts) {
    try {
      const product = new Product(productData);
      await product.save();
    } catch (err) {
      if (err.code !== 11000) {
        console.error('Error saving sample product:', err);
      }
    }
  }

  console.log(`✅ Added ${sampleProducts.length} sample products`);
}

// Helper function to determine category from product ID
function determineCategoryFromId(id) {
  if (!id) return 'General';
  
  // Based on your product ID patterns
  if (id.includes('-01-')) return 'Furniture';
  if (id.includes('-02-')) return 'Carpets';
  if (id.includes('-03-')) return 'Linens';
  
  // Check for specific patterns in your data
  const idStr = id.toString().toLowerCase();
  if (idStr.includes('250-10')) return 'Furniture';
  if (idStr.includes('250-02')) return 'Carpets';
  if (idStr.includes('250-03')) return 'Linens';
  
  return 'General';
}

// ============ ROUTES ============

// Health Check with enhanced information
app.get('/api/health', async (req, res) => {
  try {
    const productCount = await Product.countDocuments();
    const categories = await Product.distinct('category');
    const warehouses = await Product.distinct('warehouseName');
    
    res.json({ 
      status: 'OK', 
      message: 'Server is running',
      productsInDatabase: productCount,
      categoriesCount: categories.length,
      warehousesCount: warehouses.length,
      timestamp: new Date(),
      server: {
        port: PORT,
        environment: process.env.NODE_ENV || 'development',
        mongodb: MONGODB_URI
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

// Sign Up
app.post('/api/auth/signup', async (req, res) => {
  try {
    const { name, email, password, adminKey } = req.body;
    
    if (!name || !email || !password) {
      return res.status(400).json({ error: 'All fields are required' });
    }
    
    // Check if user exists
    const existingUser = await User.findOne({ email: email.toLowerCase() });
    if (existingUser) {
      return res.status(400).json({ error: 'User already exists' });
    }
    
    // Determine role - only allow admin creation with special key
    let role = 'user';
    if (adminKey === 'KABBANI_ADMIN_2024') { // Secret key for creating additional admins
      role = 'admin';
    }
    
    const hashedPassword = await bcrypt.hash(password, 10);
    
    const user = new User({
      name: name.trim(),
      email: email.toLowerCase().trim(),
      password: hashedPassword,
      role: role
    });
    
    await user.save();
    
    const token = jwt.sign(
      { id: user._id, email: user.email, role: user.role },
      JWT_SECRET,
      { expiresIn: '7d' }
    );
    
    res.status(201).json({
      message: 'User created successfully',
      user: {
        id: user._id,
        name: user.name,
        email: user.email,
        role: user.role,
        token
      }
    });
  } catch (error) {
    console.error('Signup error:', error);
    res.status(500).json({ error: 'Server error' });
  }
});

// Login
app.post('/api/auth/login', async (req, res) => {
  try {
    const { email, password } = req.body;
    
    if (!email || !password) {
      return res.status(400).json({ error: 'Email and password are required' });
    }
    
    const user = await User.findOne({ email: email.toLowerCase() });
    if (!user) {
      return res.status(401).json({ error: 'Incorrect Email Or Password Please Try Again' });
    }
    
    const isValidPassword = await bcrypt.compare(password, user.password);
    if (!isValidPassword) {
      return res.status(401).json({ error: 'Incorrect Email Or Password Please Try Again' });
    }
    
    const token = jwt.sign(
      { id: user._id, email: user.email, role: user.role }, // Include role in token
      JWT_SECRET,
      { expiresIn: '7d' }
    );
    
    res.json({
      message: 'Login successful',
      user: {
        id: user._id,
        name: user.name,
        email: user.email,
        role: user.role, // Include role in response
        token
      }
    });
  } catch (error) {
    console.error('Login error:', error);
    res.status(500).json({ error: 'Server error' });
  }
});


app.get('/api/auth/me', authenticateToken, async (req, res) => {
  try {
    const user = await User.findById(req.user.id).select('-password');
    res.json({ 
      success: true,
      user: user 
    });
  } catch (error) {
    res.status(500).json({ 
      success: false,
      error: 'Server error' 
    });
  }
});

// ============ PRODUCT ROUTES ============

// Get all products
app.get('/api/products', async (req, res) => {
  try {
    const { limit = 100, skip = 0 } = req.query;
    
    const products = await Product.find()
      .limit(parseInt(limit))
      .skip(parseInt(skip))
      .sort({ name: 1 });
      
    const total = await Product.countDocuments();
    
    res.json({
      products: products.map(p => ({
        id: p.productId,
        name: p.name,
        price: p.price,
        original_price: p.originalPrice,
        current_price: p.currentPrice,
        category: p.category,
        warehouse_name: p.warehouseName, // Added warehouse info
        sector: p.sector, // Added sector info
        current_quantity: p.currentQuantity, // Added quantity info
        discount_amount: p.discountAmount,
        discount_percentage: p.discountPercentage
      })),
      total: total,
      returned: products.length,
      hasMore: (parseInt(skip) + products.length) < total
    });
  } catch (error) {
    console.error('Get products error:', error);
    res.status(500).json({ error: 'Server error' });
  }
});

app.get('/api/products/search', async (req, res) => {
  try {
    const { id } = req.query;
    
    if (!id) {
      return res.status(400).json({ error: 'Product ID is required' });
    }
    
    console.log(`🔍 Searching for product ID: ${id}`);
    
    // Search by productId field
    const product = await Product.findOne({ productId: id.trim() });
    
    if (!product) {
      console.log(`❌ Product not found for ID: ${id}`);
      return res.status(404).json({ 
        error: 'Product not found',
        searchedId: id 
      });
    }
    
    console.log(`✅ Product found: ${product.name}`);
    console.log(`📦 Warehouse: ${product.warehouseName || 'N/A'}`);
    console.log(`📊 Quantity: ${product.currentQuantity || 0}`);
    console.log(`🏢 Sector: ${product.sector || 'N/A'}`);
    
    res.json({ 
      product: {
        id: product.productId,
        name: product.name,
        price: product.price,
        original_price: product.originalPrice || product.price,
        current_price: product.currentPrice || product.price,
        category: product.category,
        
        // ✅ THESE FIELDS WERE MISSING - NOW INCLUDED:
        warehouse_name: product.warehouseName || '',
        sector: product.sector || '',
        current_quantity: product.currentQuantity || 0,
        discount_amount: product.discountAmount || 0,
        discount_percentage: product.discountPercentage || 0,
        total_value: product.totalValue || 0,
        
        // Additional metadata
        import_date: product.importDate,
        last_updated: product.lastUpdated
      },
      message: 'Product found successfully'
    });
  } catch (error) {
    console.error('Search error:', error);
    res.status(500).json({ error: 'Server error' });
  }
});

// Advanced search by name, category, with sorting
app.get('/api/products/search-by-name', async (req, res) => {
  try {
    const { q, category, sort, warehouse } = req.query;
    
    // Build search query
    let searchQuery = {};
    
    // Search by name, ID, sector, or warehouse (supports both Arabic and English)
    if (q && q.trim() !== '') {
      searchQuery.$or = [
        { name: new RegExp(q, 'i') },
        { productId: new RegExp(q, 'i') },
        { sector: new RegExp(q, 'i') },
        { warehouseName: new RegExp(q, 'i') }
      ];
    }
    
    // Filter by category
    if (category && category !== 'All') {
      searchQuery.category = new RegExp(category, 'i');
    }
    
    // Filter by warehouse
    if (warehouse && warehouse !== 'All') {
      searchQuery.warehouseName = new RegExp(warehouse, 'i');
    }
    
    // Execute search
    let products = await Product.find(searchQuery);
    
    // Apply sorting
    switch(sort) {
      case 'name':
        products.sort((a, b) => a.name.localeCompare(b.name));
        break;
      case 'price_low':
        products.sort((a, b) => (a.currentPrice || a.price) - (b.currentPrice || b.price));
        break;
      case 'price_high':
        products.sort((a, b) => (b.currentPrice || b.price) - (a.currentPrice || a.price));
        break;
      case 'discount':
        products.sort((a, b) => b.discountPercentage - a.discountPercentage);
        break;
      case 'quantity':
        products.sort((a, b) => b.currentQuantity - a.currentQuantity);
        break;
      case 'warehouse':
        products.sort((a, b) => (a.warehouseName || '').localeCompare(b.warehouseName || ''));
        break;
      default:
        products.sort((a, b) => a.name.localeCompare(b.name));
    }
    
    res.json({
      products: products.map(p => ({
        id: p.productId,
        name: p.name,
        price: p.price,
        original_price: p.originalPrice,
        current_price: p.currentPrice,
        category: p.category,
        warehouse_name: p.warehouseName, // Added warehouse info
        sector: p.sector, // Added sector info
        current_quantity: p.currentQuantity, // Added quantity info
        discount_amount: p.discountAmount,
        discount_percentage: p.discountPercentage
      })),
      total: products.length,
      query: q || '',
      category: category || 'All',
      warehouse: warehouse || 'All',
      sort: sort || 'name'
    });
  } catch (error) {
    console.error('Search error:', error);
    res.status(500).json({ error: 'Server error' });
  }
});

app.get('/api/products/department/:department', async (req, res) => {
  try {
    const { department } = req.params;
    const products = await Product.find({ 
      category: new RegExp(department, 'i') 
    });
    
    res.json({
      department,
      products: products.map(p => ({
        id: p.productId,
        name: p.name,
        price: p.price,
        original_price: p.originalPrice,
        current_price: p.currentPrice,
        category: p.category,
        warehouse_name: p.warehouseName, // Added warehouse info
        sector: p.sector, // Added sector info
        current_quantity: p.currentQuantity // Added quantity info
      })),
      total: products.length
    });
  } catch (error) {
    console.error('Get department products error:', error);
    res.status(500).json({ error: 'Server error' });
  }
});

app.put('/api/admin/products/:productId/quantity', authenticateToken, requireAdmin, async (req, res) => {
  try {
    const { productId } = req.params;
    const { quantity } = req.body;
    
    if (quantity === undefined || quantity < 0) {
      return res.status(400).json({ error: 'Valid quantity required (must be >= 0)' });
    }
    
    const product = await Product.findOne({ productId: productId });
    if (!product) {
      return res.status(404).json({ error: 'Product not found' });
    }
    
    const oldQuantity = product.currentQuantity;
    
    // Update quantity
    product.currentQuantity = parseInt(quantity);
    product.lastUpdated = new Date();
    product.totalValue = product.currentQuantity * (product.currentPrice || product.price);
    
    await product.save();
    
    // Log the change
    console.log(`📊 ADMIN UPDATE - ${product.name}: ${oldQuantity} → ${quantity} by ${req.user.email}`);
    
    res.json({
      success: true,
      message: 'Quantity updated successfully',
      product: {
        id: product.productId,
        name: product.name,
        old_quantity: oldQuantity,
        new_quantity: product.currentQuantity,
        updated_by: req.user.email
      }
    });
    
  } catch (error) {
    console.error('Update quantity error:', error);
    res.status(500).json({ error: 'Server error' });
  }
});

// NEW: Get warehouses list
app.get('/api/warehouses', async (req, res) => {
  try {
    const warehouses = await Product.distinct('warehouseName');
    res.json({
      warehouses: warehouses.filter(w => w && w.trim() !== ''), // Remove null/empty warehouses
      total: warehouses.length
    });
  } catch (error) {
    console.error('Get warehouses error:', error);
    res.status(500).json({ error: 'Server error' });
  }
});

// NEW: Get products by warehouse
app.get('/api/products/warehouse/:warehouse', async (req, res) => {
  try {
    const { warehouse } = req.params;
    const products = await Product.find({ 
      warehouseName: new RegExp(warehouse, 'i') 
    });
    
    res.json({
      warehouse,
      products: products.map(p => ({
        id: p.productId,
        name: p.name,
        price: p.price,
        original_price: p.originalPrice,
        current_price: p.currentPrice,
        category: p.category,
        warehouse_name: p.warehouseName,
        sector: p.sector,
        current_quantity: p.currentQuantity,
        discount_amount: p.discountAmount,
        discount_percentage: p.discountPercentage,
        total_value: p.totalValue
      })),
      total: products.length
    });
  } catch (error) {
    console.error('Get warehouse products error:', error);
    res.status(500).json({ error: 'Server error' });
  }
});

// NEW: Get warehouse statistics
app.get('/api/warehouses/stats', async (req, res) => {
  try {
    const warehouseStats = await Product.aggregate([
      {
        $group: {
          _id: '$warehouseName',
          totalProducts: { $sum: 1 },
          totalQuantity: { $sum: '$currentQuantity' },
          totalValue: { $sum: '$totalValue' },
          averagePrice: { $avg: '$currentPrice' },
          categories: { $addToSet: '$category' }
        }
      },
      {
        $sort: { totalValue: -1 }
      }
    ]);
    
    res.json({
      warehouses: warehouseStats.map(w => ({
        name: w._id,
        total_products: w.totalProducts,
        total_quantity: w.totalQuantity,
        total_value: w.totalValue,
        average_price: w.averagePrice,
        categories_count: w.categories.length,
        categories: w.categories
      })),
      total: warehouseStats.length
    });
  } catch (error) {
    console.error('Get warehouse stats error:', error);
    res.status(500).json({ error: 'Server error' });
  }
});

// Get categories list
app.get('/api/categories', async (req, res) => {
  try {
    const categories = await Product.distinct('category');
    res.json({
      categories: categories.filter(c => c && c.trim() !== ''), // Remove null/empty categories
      total: categories.length
    });
  } catch (error) {
    console.error('Get categories error:', error);
    res.status(500).json({ error: 'Server error' });
  }
});

// Get product suggestions (for autocomplete)
app.get('/api/products/suggestions', async (req, res) => {
  try {
    const { q } = req.query;
    
    if (!q || q.length < 2) {
      return res.json({ suggestions: [] });
    }
    
    const products = await Product.find({
      $or: [
        { name: new RegExp(q, 'i') },
        { productId: new RegExp(q, 'i') }
      ]
    }).limit(10);
    
    res.json({
      suggestions: products.map(p => ({
        id: p.productId,
        name: p.name,
        category: p.category
      }))
    });
  } catch (error) {
    console.error('Get suggestions error:', error);
    res.status(500).json({ error: 'Server error' });
  }
});

app.get('/api/debug/product/:id', async (req, res) => {
  try {
    const { id } = req.params;
    console.log(`🐛 DEBUG: Checking MongoDB for product ID: ${id}`);
    
    // Find the product in MongoDB
    const product = await Product.findOne({ productId: id });
    
    if (!product) {
      return res.json({ 
        found: false, 
        message: `No product found with ID: ${id}`,
        searchedId: id
      });
    }
    
    console.log(`🐛 DEBUG: Raw MongoDB document:`, product.toObject());
    
    res.json({
      found: true,
      message: `Product found: ${product.name}`,
      rawDocument: product.toObject(),
      fieldCheck: {
        hasProductId: !!product.productId,
        hasName: !!product.name,
        hasWarehouseName: !!product.warehouseName,
        hasSector: !!product.sector,
        hasCurrentQuantity: product.currentQuantity !== undefined,
        hasCurrentPrice: !!product.currentPrice,
        hasPrice: !!product.price,
        hasOriginalPrice: !!product.originalPrice
      },
      values: {
        productId: product.productId,
        name: product.name,
        warehouseName: product.warehouseName,
        sector: product.sector,
        currentQuantity: product.currentQuantity,
        currentPrice: product.currentPrice,
        price: product.price,
        originalPrice: product.originalPrice,
        category: product.category,
        discountAmount: product.discountAmount,
        discountPercentage: product.discountPercentage,
        totalValue: product.totalValue
      }
    });
  } catch (error) {
    console.error('🐛 DEBUG Error:', error);
    res.status(500).json({ error: error.message });
  }
});

// Also add this route to see a sample of all products
app.get('/api/debug/sample', async (req, res) => {
  try {
    const sampleProduct = await Product.findOne();
    
    if (!sampleProduct) {
      return res.json({ message: 'No products in database' });
    }
    
    res.json({
      message: 'Sample product from database',
      document: sampleProduct.toObject(),
      schema: {
        availableFields: Object.keys(sampleProduct.toObject()),
        fieldTypes: Object.entries(sampleProduct.toObject()).reduce((acc, [key, value]) => {
          acc[key] = typeof value;
          return acc;
        }, {})
      }
    });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// ============ START SERVER ============
app.listen(PORT, '0.0.0.0', () => {
  console.log(`
    🚀 Server is running on http://0.0.0.0:${PORT}
  `);
});