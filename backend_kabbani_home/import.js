// Import Script for home_furnishing Database
// Save this as import_furniture.js

const { MongoClient } = require('mongodb');
const XLSX = require('xlsx');

async function importToHomeFurnishing() {
    let client;
    
    try {
        console.log('🚀 Starting import to home_furnishing database...');
        
        // 1. Read Excel file
        console.log('📖 Reading Excel file...');
        const workbook = XLSX.readFile('كميات المفروشات في الصعيد 28.8.xlsx');
        const worksheet = workbook.Sheets[workbook.SheetNames[0]];
        const rawData = XLSX.utils.sheet_to_json(worksheet);
        
        console.log(`✅ Found ${rawData.length} records in Excel file`);
        
        // 2. Transform data for your database
        console.log('🔄 Transforming data...');
        const transformedData = rawData.map((row, index) => {
            return {
                _id: `${row.ID}_${index}`, // Unique ID
                
                // Basic product info
                productId: row['ID'],
                productName: row['اسم الصنف'],
                sector: row['القطاع'],
                
                // Warehouse info
                warehouseName: row['اسم المخزن'],
                currentQuantity: parseInt(row['الكمية الحالية للمخازن']) || 0,
                
                // Pricing info
                currentPrice: parseFloat(row['السعر الحالي']) || 0,
                regularPrice: parseFloat(row['السعر']) || 0,
                priceBeforeDiscount: parseFloat(row['قبل الخصم']) || 0,
                
                // Calculated fields
                discountAmount: (parseFloat(row['قبل الخصم']) || 0) - (parseFloat(row['السعر']) || 0),
                discountPercentage: row['قبل الخصم'] ? 
                    parseFloat(((parseFloat(row['قبل الخصم']) - parseFloat(row['السعر'])) / parseFloat(row['قبل الخصم']) * 100).toFixed(2)) : 0,
                
                // Inventory value
                totalValue: (parseInt(row['الكمية الحالية للمخازن']) || 0) * (parseFloat(row['السعر الحالي']) || 0),
                
                // Metadata
                importDate: new Date(),
                lastUpdated: new Date(),
                
                // Keep original Arabic data
                originalData: {
                    القطاع: row['القطاع'],
                    ID: row['ID'],
                    اسم_الصنف: row['اسم الصنف'],
                    اسم_المخزن: row['اسم المخزن'],
                    الكمية_الحالية_للمخازن: row['الكمية الحالية للمخازن'],
                    السعر_الحالي: row['السعر الحالي'],
                    السعر: row['السعر'],
                    قبل_الخصم: row['قبل الخصم']
                }
            };
        });
        
        console.log('✅ Data transformation completed');
        
        // 3. Connect to your MongoDB
        console.log('🔌 Connecting to MongoDB...');
        client = new MongoClient('mongodb://localhost:27017');
        await client.connect();
        console.log('✅ Connected to MongoDB successfully');
        
        // 4. Use your existing database
        const db = client.db('home_furnishing');
        const collection = db.collection('furniture_inventory'); // New collection for your furniture data
        
        // 5. Create indexes for better performance
        console.log('📊 Creating indexes...');
        await collection.createIndex({ productId: 1 });
        await collection.createIndex({ productName: 1 });
        await collection.createIndex({ warehouseName: 1 });
        await collection.createIndex({ sector: 1 });
        await collection.createIndex({ currentQuantity: 1 });
        await collection.createIndex({ currentPrice: 1 });
        
        // 6. Import data (replace existing data)
        console.log('🗑️ Clearing existing furniture data...');
        await collection.deleteMany({});
        
        console.log('📥 Importing furniture data...');
        
        // Insert in batches for better performance
        const batchSize = 100;
        let totalInserted = 0;
        
        for (let i = 0; i < transformedData.length; i += batchSize) {
            const batch = transformedData.slice(i, i + batchSize);
            const result = await collection.insertMany(batch, { ordered: false });
            totalInserted += result.insertedCount;
            console.log(`   Batch ${Math.floor(i/batchSize) + 1}: ${result.insertedCount} documents inserted`);
        }
        
        console.log(`\n🎉 SUCCESS! Imported ${totalInserted} furniture records`);
        
        // 7. Generate summary
        console.log('\n📈 Generating summary...');
        const stats = await generateSummary(collection);
        
        console.log('\n' + '='.repeat(60));
        console.log('📊 IMPORT SUMMARY');
        console.log('='.repeat(60));
        console.log(`Database: home_furnishing`);
        console.log(`Collection: furniture_inventory`);
        console.log(`Total Products: ${stats.totalProducts}`);
        console.log(`Unique Products: ${stats.uniqueProducts}`);
        console.log(`Total Warehouses: ${stats.totalWarehouses}`);
        console.log(`Total Quantity: ${stats.totalQuantity}`);
        console.log(`Total Inventory Value: ${stats.totalValue.toLocaleString()} EGP`);
        console.log(`Average Price: ${stats.averagePrice.toFixed(2)} EGP`);
        
        console.log('\n🏆 Top 5 Products by Quantity:');
        stats.topProducts.forEach((product, index) => {
            console.log(`   ${index + 1}. ${product._id}: ${product.totalQuantity} units`);
        });
        
        console.log('\n🏪 Warehouses:');
        stats.warehouses.forEach((warehouse, index) => {
            console.log(`   ${index + 1}. ${warehouse._id}: ${warehouse.productCount} products`);
        });
        
        console.log('\n✅ Data is now available in MongoDB Compass!');
        console.log('   Database: home_furnishing');
        console.log('   Collection: furniture_inventory');
        
    } catch (error) {
        console.error('\n❌ Error during import:', error.message);
        
        if (error.message.includes('ENOENT')) {
            console.log('\n💡 Solutions:');
            console.log('   • Make sure the Excel file is in the same folder as this script');
            console.log('   • Check the file name: كميات المفروشات في الصعيد 28.8.xlsx');
        }
        
        if (error.message.includes('ECONNREFUSED')) {
            console.log('\n💡 MongoDB connection issue:');
            console.log('   • Make sure MongoDB is running');
            console.log('   • Check if localhost:27017 is accessible');
        }
        
    } finally {
        if (client) {
            await client.close();
            console.log('\n🔌 MongoDB connection closed');
        }
    }
}

async function generateSummary(collection) {
    const totalProducts = await collection.countDocuments();
    const uniqueProducts = (await collection.distinct('productId')).length;
    const totalWarehouses = (await collection.distinct('warehouseName')).length;
    
    // Calculate totals
    const aggregation = await collection.aggregate([
        {
            $group: {
                _id: null,
                totalQuantity: { $sum: '$currentQuantity' },
                totalValue: { $sum: '$totalValue' },
                averagePrice: { $avg: '$currentPrice' }
            }
        }
    ]).toArray();
    
    const totals = aggregation[0] || { totalQuantity: 0, totalValue: 0, averagePrice: 0 };
    
    // Top products
    const topProducts = await collection.aggregate([
        {
            $group: {
                _id: '$productName',
                totalQuantity: { $sum: '$currentQuantity' }
            }
        },
        { $sort: { totalQuantity: -1 } },
        { $limit: 5 }
    ]).toArray();
    
    // Warehouses
    const warehouses = await collection.aggregate([
        {
            $group: {
                _id: '$warehouseName',
                productCount: { $sum: 1 }
            }
        },
        { $sort: { productCount: -1 } }
    ]).toArray();
    
    return {
        totalProducts,
        uniqueProducts,
        totalWarehouses,
        totalQuantity: totals.totalQuantity,
        totalValue: totals.totalValue,
        averagePrice: totals.averagePrice,
        topProducts,
        warehouses
    };
}

// Run the import
importToHomeFurnishing()
    .then(() => {
        console.log('\n🎊 Import completed successfully!');
        console.log('🔍 Check MongoDB Compass to see your data');
    })
    .catch(error => {
        console.error('\n💥 Import failed:', error);
    });