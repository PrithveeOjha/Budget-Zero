# BudgetZero

A privacy-focused, zero-based budgeting mobile application built with Flutter, designed to help users break the paycheck-to-paycheck cycle.

**Developed By: prithV33**

## Core Philosophy

> **"Give Every Dollar a Job"**

Unlike traditional expense trackers, BudgetZero forces you to allocate every dollar of your income to specific categories *before* you spend it. This proactive approach to budgeting helps you make intentional financial decisions.

## Features

### Zero-Based Budgeting Engine
- **Immediate Allocation**: Income goes to "To Be Budgeted" and must be assigned to categories
- **Envelope Logic**: Spending deducts from category balances, not just account balances
- **Automatic Rollovers**: Positive category balances roll over to the next month
- **Overspending Alerts**: Visual indicators when categories go negative

### Mobile-First Design
- **Bottom Navigation**: Easy one-handed access to Budget, Accounts, and Transactions
- **Large FAB**: Quick transaction entry with a prominent floating action button
- **Custom Numeric Keypad**: Calculator-style input without system keyboard interference
- **Thumb Zone Optimization**: Important actions placed in the bottom 30% of the screen

### Budget Management
- **Category Groups**: Organize categories (Bills, Needs, Wants, Savings Goals)
- **Move Money**: Swipe on categories to transfer funds between them
- **Monthly Navigation**: View and manage budgets for any month
- **"To Be Budgeted" Display**: Always know how much money needs assignment

### Account Management
- **Multiple Account Types**: Cash, Savings, and Credit Card accounts
- **Net Worth Tracking**: See your total financial position at a glance
- **Balance Editing**: Reconcile accounts with real-world balances

### Transaction Tracking
- **Income & Expenses**: Track both money in and money out
- **Category Assignment**: Every expense is tied to a budget category
- **Swipe to Delete**: Quick removal of incorrect transactions
- **Date Selection**: Log transactions for any date

### User Experience
- **Material 3 Design**: Modern, clean interface following Material You guidelines
- **Dark Mode**: Full dark theme support with manual toggle
- **Haptic Feedback**: Tactile responses for key interactions
- **Animated Splash Screen**: Polished app startup experience

### Privacy & Security
- **100% Local Storage**: All data stored on-device using SQLite
- **No Cloud Required**: Works completely offline
- **No Account Needed**: No sign-up, no tracking, no data collection

## Screenshots

| Splash Screen | Budget View | Add Transaction |
|---------------|-------------|-----------------|
| *Animated startup* | *Category management* | *Custom keypad* |

| Accounts | Transactions | Settings |
|----------|--------------|----------|
| *Net worth overview* | *Transaction history* | *Theme & currency* |

## Tech Stack

- **Framework**: Flutter 3.10+
- **State Management**: Provider
- **Database**: SQLite (sqflite)
- **Design System**: Material 3 (Material You)
- **Languages**: Dart

## Project Structure

```
lib/
├── main.dart                      # App entry point, routing, theme configuration
│
├── models/                        # Data models
│   ├── account.dart               # Account model (cash, credit, savings)
│   ├── category.dart              # CategoryGroup and BudgetCategory models
│   ├── monthly_budget.dart        # Monthly budget envelope model
│   ├── transaction.dart           # Transaction model
│   └── models.dart                # Barrel export
│
├── providers/                     # State management
│   └── budget_provider.dart       # Main app state, business logic
│
├── screens/                       # UI screens
│   ├── splash_screen.dart         # Animated splash screen
│   ├── budget_screen.dart         # Budget categories view
│   ├── accounts_screen.dart       # Account management
│   ├── transactions_screen.dart   # Transaction history
│   ├── add_transaction_screen.dart # New transaction form
│   ├── settings_screen.dart       # App settings
│   └── screens.dart               # Barrel export
│
├── services/                      # Data layer
│   └── database_service.dart      # SQLite database operations
│
└── widgets/                       # Reusable components
    ├── numeric_keypad.dart        # Calculator-style number input
    ├── move_money_sheet.dart      # Category transfer bottom sheet
    └── widgets.dart               # Barrel export
```

## Database Schema

```sql
-- User accounts (bank accounts, wallets, credit cards)
CREATE TABLE accounts (
    id TEXT PRIMARY KEY,
    name TEXT NOT NULL,
    type INTEGER NOT NULL,        -- 0: cash, 1: credit, 2: savings
    balance REAL NOT NULL
);

-- Budget category groups
CREATE TABLE category_groups (
    id TEXT PRIMARY KEY,
    name TEXT NOT NULL,
    sort_order INTEGER DEFAULT 0
);

-- Budget categories
CREATE TABLE categories (
    id TEXT PRIMARY KEY,
    group_id TEXT NOT NULL,
    name TEXT NOT NULL,
    target_amount REAL,
    sort_order INTEGER DEFAULT 0,
    FOREIGN KEY (group_id) REFERENCES category_groups (id)
);

-- Monthly budget allocations (the "envelopes")
CREATE TABLE monthly_budgets (
    id TEXT PRIMARY KEY,
    category_id TEXT NOT NULL,
    month TEXT NOT NULL,          -- Format: "YYYY-MM"
    assigned REAL DEFAULT 0,
    activity REAL DEFAULT 0,
    FOREIGN KEY (category_id) REFERENCES categories (id)
);

-- Financial transactions
CREATE TABLE transactions (
    id TEXT PRIMARY KEY,
    amount REAL NOT NULL,
    date TEXT NOT NULL,
    payee TEXT NOT NULL,
    category_id TEXT,
    account_id TEXT NOT NULL,
    memo TEXT,
    is_income INTEGER DEFAULT 0,
    FOREIGN KEY (category_id) REFERENCES categories (id),
    FOREIGN KEY (account_id) REFERENCES accounts (id)
);

-- App settings
CREATE TABLE settings (
    key TEXT PRIMARY KEY,
    value TEXT
);
```

## Installation

### Prerequisites

- Flutter SDK 3.10 or higher
- Dart SDK 3.0 or higher
- Android Studio / Xcode (for mobile development)

### Setup

1. **Clone the repository**
   ```bash
   git clone https://github.com/yourusername/budget_zero.git
   cd budget_zero
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Generate native splash screen**
   ```bash
   dart run flutter_native_splash:create
   ```

4. **Run the app**
   ```bash
   # For debug mode
   flutter run

   # For release mode
   flutter run --release
   ```

### Building for Production

```bash
# Android APK
flutter build apk --release

# Android App Bundle (for Play Store)
flutter build appbundle --release

# iOS (requires macOS)
flutter build ios --release
```

## Usage Guide

### Getting Started

1. **Launch the app** - You'll see the animated splash screen
2. **Add an account** - Go to Settings > Add Account
   - Enter account name (e.g., "Main Checking")
   - Select type (Cash, Savings, or Credit)
   - Enter current balance
3. **Budget your money** - On the Budget screen:
   - Your account balance appears as "To Be Budgeted"
   - Tap a category to assign money to it
   - Keep assigning until "To Be Budgeted" is zero

### Recording Transactions

1. Tap the large **+** button
2. Enter the amount using the custom keypad
3. Tap **Done** to proceed
4. Fill in:
   - Payee name
   - Account
   - Category (for expenses)
   - Date and memo (optional)
5. Tap **Save Transaction**

### Moving Money Between Categories

When you overspend in a category, you can "roll with the punches":

1. **Swipe left** on a category, or
2. **Long-press** on a category
3. Select the destination category
4. Enter the amount to transfer
5. Tap **Move Money**

### Changing Settings

Access Settings via the gear icon:
- **Currency**: USD, INR, EUR, GBP
- **Theme**: System, Light, or Dark
- **Categories**: Add custom category groups and categories
- **Accounts**: Add new financial accounts

## The Zero-Based Budgeting Method

### How It Works

```
To Be Budgeted = Total Account Balances - Total Assigned to Categories
```

1. **Start with your money**: Add all your accounts with current balances
2. **Assign every dollar**: Distribute "To Be Budgeted" across categories
3. **Spend from categories**: When you buy something, it reduces that category's balance
4. **Adjust as needed**: Move money between categories when plans change
5. **Repeat monthly**: Positive balances roll over, negative ones need covering

### The Four Rules

1. **Give Every Dollar a Job**: Assign all money to categories before spending
2. **Embrace Your True Expenses**: Budget for large, infrequent expenses monthly
3. **Roll With the Punches**: Move money when priorities change
4. **Age Your Money**: Work toward spending money that's at least 30 days old

## Architecture Overview

### App Navigation Flow

```
┌─────────────────────────────────────────────────────────────┐
│                      SplashScreen                            │
│            Initializes database, loads all data              │
│                 Shows error + retry if failed                │
└──────────────────────────┬──────────────────────────────────┘
                           ▼
┌─────────────────────────────────────────────────────────────┐
│                        HomePage                              │
│  ┌───────────────┬─────────────────┬─────────────────────┐  │
│  │    Budget     │    Accounts     │    Transactions     │  │
│  │               │                 │                     │  │
│  │ • To Be       │ • Account list  │ • Transaction       │  │
│  │   Budgeted    │ • Net worth     │   history           │  │
│  │ • Categories  │ • Add/edit      │ • Swipe to delete   │  │
│  │ • Assign $    │   accounts      │                     │  │
│  └───────────────┴─────────────────┴─────────────────────┘  │
│                                                              │
│                    [ + FAB Button ]                          │
│                           │                                  │
│                           ▼                                  │
│                 AddTransactionScreen                         │
│                 • Amount keypad                              │
│                 • Payee, account, category                   │
│                 • Income/expense toggle                      │
│                                                              │
│  [Settings Icon] ──────► SettingsScreen                      │
│                          • Theme toggle                      │
│                          • Currency selection                │
│                          • Add categories/groups             │
│                          • Add accounts                      │
└─────────────────────────────────────────────────────────────┘
```

### State Management

BudgetZero uses the **Provider** pattern for state management:

```dart
// Access state anywhere in the widget tree
final provider = context.watch<BudgetProvider>();

// Read without rebuilding
final provider = context.read<BudgetProvider>();
```

### Data Flow

```
UI (Screens/Widgets)
        ↓↑
BudgetProvider (State Management)
        ↓↑
DatabaseService (Data Persistence)
        ↓↑
SQLite Database (Local Storage)
```

### How Transactions Work Internally

When you add a **$50 grocery expense**:

```
Step 1: Account balance decreases
        Checking: $1000 → $950  (-$50)

Step 2: Category activity updates
        Groceries activity: $0 → -$50

Step 3: Category available recalculates
        available = assigned + activity
        If assigned was $200: available = $200 + (-$50) = $150

Step 4: "To Be Budgeted" unchanged
        (Money moved from account to spending, not created/destroyed)
```

When you add **$2000 income**:

```
Step 1: Account balance increases
        Checking: $950 → $2950  (+$2000)

Step 2: "To Be Budgeted" increases
        New money enters the system and needs assignment

Step 3: No category affected
        Income doesn't belong to a category until you assign it
```

When you **assign $300 to Rent**:

```
Step 1: Monthly budget updates
        Rent assigned: $0 → $300

Step 2: "To Be Budgeted" decreases
        $2000 → $1700  (-$300)

Step 3: Category available updates
        Rent available = $300 + $0 (activity) = $300
```

### Key Classes

| Class | Responsibility |
|-------|----------------|
| `BudgetProvider` | Central state management, business logic |
| `DatabaseService` | SQLite CRUD operations |
| `Account` | Bank account/wallet data model |
| `BudgetCategory` | Budget category with group association |
| `MonthlyBudget` | Monthly allocation tracking (envelope) |
| `BudgetTransaction` | Income/expense records |

## Contributing

Contributions are welcome! Please follow these steps:

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

### Development Guidelines

- Follow the [Flutter style guide](https://dart.dev/guides/language/effective-dart/style)
- Write meaningful commit messages
- Add tests for new features
- Update documentation as needed

### Code Style

```dart
// Use trailing commas for better formatting
Widget build(BuildContext context) {
  return Container(
    padding: const EdgeInsets.all(16),
    child: Column(
      children: [
        Text('Hello'),
        Text('World'),
      ],
    ),
  );
}
```

## Roadmap

### Planned Features

- [ ] Biometric authentication (fingerprint/face unlock)
- [ ] Data export/import (CSV, JSON)
- [ ] Recurring transactions
- [ ] Budget templates
- [ ] Spending reports and charts
- [ ] Category goals and targets
- [ ] Multi-currency support
- [ ] Optional cloud sync (self-hosted)
- [ ] Widgets for home screen
- [ ] Notifications for overspending

### Version History

- **v1.0.0** - Initial release
  - Zero-based budgeting engine
  - Account management
  - Transaction tracking
  - Category management
  - Dark mode support
  - Custom numeric keypad
  - Move money feature

## Troubleshooting

### Common Issues

**App crashes on startup**
- Ensure Flutter SDK is up to date: `flutter upgrade`
- Clear build cache: `flutter clean && flutter pub get`

**Database errors**
- Delete app data and reinstall
- Check device storage space

**Splash screen not showing**
- Regenerate: `dart run flutter_native_splash:create`

### Getting Help

- Check [existing issues](https://github.com/yourusername/budget_zero/issues)
- Open a new issue with detailed description
- Include Flutter version (`flutter --version`)

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

```
MIT License

Copyright (c) 2025 prithV33

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```

## Acknowledgments

- Built with [Flutter](https://flutter.dev/)
- Icons from [Material Design Icons](https://material.io/icons/)
- Database powered by [sqflite](https://pub.dev/packages/sqflite)

## Support

If you find this project helpful, please consider:
- Starring the repository
- Reporting bugs or suggesting features via Issues
- Contributing code or documentation
- Sharing with others who might benefit

---

<p align="center">
  <strong>BudgetZero</strong> - Take control of your finances, one dollar at a time.
</p>
