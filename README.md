# 🏠 Home Furnishing App

A professional Flutter application designed for Home Furnishing workers to efficiently manage product scanning, searching, and inventory tracking.

![Flutter](https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white)
![Dart](https://img.shields.io/badge/Dart-0175C2?style=for-the-badge&logo=dart&logoColor=white)
![Node.js](https://img.shields.io/badge/Node.js-43853D?style=for-the-badge&logo=node.js&logoColor=white)
![MongoDB](https://img.shields.io/badge/MongoDB-4EA94B?style=for-the-badge&logo=mongodb&logoColor=white)

## 📱 Features

### 🔐 Authentication System
- **Secure Login/Signup** with form validation
- **Worker account management** with personalized profiles
- **Auto-login after registration** for seamless onboarding
- **Session management** with logout functionality

### 🏠 Home Dashboard
- **Personalized welcome screen** with worker name display
- **Real-time activity counters** for scanned and searched products
- **Quick action cards** for instant access to main features
- **Category browsing** with visual department cards
- **Today's activity tracking** with reset functionality

### 🔍 Product Management
- **Barcode scanning simulation** with increment counters
- **Advanced product search** by name, ID, or category
- **Search by specific ID** with detailed product information
- **Category-based filtering** (Furniture, Carpets, Linens, General)
- **Real-time search results** with comprehensive product details

### 👤 User Profile
- **Worker information display** with personalized avatars
- **Activity statistics** showing scanned/searched counts
- **Profile management options** (Settings, Help, About)
- **Secure logout** with confirmation dialog

### 🎨 Modern UI/UX
- **Dark theme** with professional color scheme
- **Transparent bottom navigation** for clean aesthetics
- **Responsive design** optimized for mobile devices
- **Intuitive navigation** with bottom tab bar
- **Loading states** and user feedback mechanisms

## 🚀 Getting Started

### Prerequisites

- **Flutter SDK** (3.0.0 or higher)
- **Dart SDK** (2.17.0 or higher)
- **Node.js** (16.0.0 or higher)
- **MongoDB** (5.0.0 or higher)
- **Android Studio** or **VS Code** with Flutter extensions

### 📦 Installation

1. **Clone the repository**
```

git clone https://github.com/yourusername/home-furnishing-app.git
cd home-furnishing-app

```

2. **Install Flutter dependencies**
```

flutter pub get

```

3. **Set up the backend server**
```

cd backend
npm install

```

4. **Configure MongoDB**
- Install MongoDB on your system
- Create a database named `home_furnishing`
- Import sample product data (if available)

5. **Start the backend server**
```

npm start

# Server will run on http://localhost:3000

```

6. **Update API configuration**
- Open `lib/services/api_service.dart`
- Update the `baseUrl` with your server IP:
```

static const String baseUrl = 'http://YOUR_IP:3000/api';

```

7. **Run the Flutter app**
```

flutter run

```

## 🏗️ Project Structure

```

home_furnishing_app/
├── lib/
│   ├── models/               # Data models
│   │   └── product.dart
│   ├── screens/              # App screens
│   │   ├── auth/             # Authentication screens
│   │   │   ├── login_screen.dart
│   │   │   └── signup_screen.dart
│   │   ├── home/             # Home dashboard
│   │   │   └── home_screen.dart
│   │   ├── profile/          # User profile
│   │   │   └── profile_screen.dart
│   │   ├── search/           # Search functionality
│   │   │   ├── advanced_search_screen.dart
│   │   │   ├── barcode_scanner_screen.dart
│   │   │   └── search_by_id_screen.dart
│   │   └── products/         # Product screens
│   │       ├── all_products_screen.dart
│   │       └── category_products_screen.dart
│   ├── services/             # API and business logic
│   │   └── api_service.dart
│   ├── widgets/              # Reusable UI components
│   │   └── custom_widgets.dart
│   └── main.dart            # App entry point
├── backend/                 # Node.js backend
│   ├── models/              # Database models
│   ├── routes/              # API routes
│   ├── middleware/          # Authentication middleware
│   └── server.js            # Server entry point
└── README.md

```

## 🔧 Backend API Endpoints

### Authentication
- `POST /api/auth/login` - User login
- `POST /api/auth/signup` - User registration
- `POST /api/auth/logout` - User logout

### Products
- `GET /api/products` - Get all products
- `GET /api/products/search?id={id}` - Search by product ID
- `GET /api/products/search-by-name?q={query}` - Search by name
- `GET /api/products/department/{category}` - Get products by category
- `GET /api/categories` - Get all categories

### System
- `GET /api/health` - Health check endpoint

## 📱 Screenshots

### Authentication Flow
| Login Screen | Signup Screen |
|:---:|:---:|
| ![Login](screenshots/login.png) | ![Signup](screenshots/signup.png) |

### Main Application
| Home Dashboard | Product Search | User Profile |
|:---:|:---:|:---:|
| ![Home](screenshots/home.png) | ![Search](screenshots/search.png) | ![Profile](screenshots/profile.png) |

## 🛠️ Configuration

### API Configuration
Update the base URL in `lib/services/api_service.dart`:

```

// For Android Emulator
static const String baseUrl = 'http://10.0.2.2:3000/api';

// For iOS Simulator
static const String baseUrl = 'http://localhost:3000/api';

// For Real Device
static const String baseUrl = 'http://YOUR_COMPUTER_IP:3000/api';

```

### Database Configuration
Update MongoDB connection in `backend/config/database.js`:

```

const mongoURI = 'mongodb://localhost:27017/home_furnishing';

```

## 🧪 Testing

### Run Flutter Tests
```

flutter test

```

### Run Backend Tests
```

cd backend
npm test

```

### Test Coverage
```

flutter test --coverage
genhtml coverage/lcov.info -o coverage/html

```

## 📋 Features Roadmap

- [ ] **Real barcode scanning** with camera integration
- [ ] **Offline mode** with local data synchronization
- [ ] **Push notifications** for inventory updates
- [ ] **Advanced filtering** with price ranges and availability
- [ ] **Export functionality** for reports and data
- [ ] **Multi-language support** for international use
- [ ] **Dark/Light theme toggle** for user preference
- [ ] **Product image management** with cloud storage

## 🤝 Contributing

We welcome contributions to improve the Home Furnishing App! Here's how you can help:

1. **Fork the repository**
2. **Create a feature branch** (`git checkout -b feature/AmazingFeature`)
3. **Commit your changes** (`git commit -m 'Add some AmazingFeature'`)
4. **Push to the branch** (`git push origin feature/AmazingFeature`)
5. **Open a Pull Request**

### Code Style Guidelines
- Follow **Dart style guide** conventions
- Use **meaningful variable and function names**
- Add **comments** for complex logic
- Write **unit tests** for new features
- Ensure **responsive design** principles

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

```

MIT License

Copyright (c) 2025 Home Furnishing App

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

```

## 📞 Support

If you encounter any issues or have questions:

- **Create an issue** on GitHub
- **Email support**: support@homefurnishing.app
- **Documentation**: Check our [Wiki](https://github.com/yourusername/home-furnishing-app/wiki)

## 🙏 Acknowledgments

- **Flutter Team** for the amazing framework
- **MongoDB** for reliable database solutions
- **Node.js Community** for excellent backend tools
- **Material Design** for UI/UX inspiration
- **Contributors** who helped improve this project

## 📊 Project Stats

- **Lines of Code**: ~5,000+
- **Development Time**: 3 weeks
- **Supported Platforms**: Android, iOS
- **Backend**: Node.js + Express + MongoDB
- **Frontend**: Flutter + Dart
