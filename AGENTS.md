# Fix Summary

## Issues Addressed:

### 1. Crypto Data Parsing Fix
**Location**: `lib/screens/crypto_detail_screen.dart` line 195
**Change**: 
```dart
// Before
setState(() => _selectedDays = (period['days'] as int?) ?? 30);

// After  
setState(() => _selectedDays = parseInt(period['days']) ?? 30);
```
**Why**: Replace unsafe cast with safe parser to prevent "type string is not subtype of int" errors when API returns string values.

### 2. Stock Name Display Improvements Needed

#### WatchlistScreen (`lib/screens/watchlist_screen.dart`)
**Current**: Line 253 shows `item.ticker` as main title, name as smaller subtitle
**Fix**: Show name prominently using `item.nameAr ?? item.name ?? item.ticker` as main title

#### PortfolioScreen (`lib/screens/portfolio_screen.dart`) 
**Current**: Line 320 shows `pos.stockSymbol` as main title, stockName as smaller subtitle
**Fix**: Show name prominently using `pos.stockName ?? pos.stockSymbol` as main title

### 3. TradingView Chart Enhancement Plan
**Files**: 
- `lib/widgets/tradingview_chart.dart`
- `assets/charts/tradingview.html`

**To Add**:
- `chartType` property: 'candle', 'line', 'area'
- `interval` property: string/enum (1D, 1W, 1M, 3M, 6M, 1Y, ALL)
- Dynamic update methods
- HTML/JS support for chart type switching

### 4. Local Historical Data Plan
**Location**: `lib/api/local_database.dart`

**To Add**:
- `stock_history` table: id, ticker, timestamp, open, high, low, close, volume
- Migration script for new table
- Sync logic to populate from API/asset DB
- Local-first loading strategy for charts

## Verification
After fixes:
1. Crypto API calls successfully (visible in logs)
2. No parsing errors
3. Stock names displayed prominently in all screens
4. Ready for TradingView and local DB enhancements