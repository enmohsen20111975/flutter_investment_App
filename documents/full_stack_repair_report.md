# Full Stack Repair Report: Resolving Empty Data Across Mobile Screens

This report details the root causes of the empty data screens in the Investment Assistant (مساعد الاستثمار) mobile application and provides the exact file paths and code modifications required to resolve them. 

---

## 📋 Executive Summary
1. **Backend API Database Mismatch**: 
   The Next.js mobile endpoints (Dashboard, Market Overview, Recommendations, Reports, Alerts, and AI Insights) were querying the `stocks` table in `stocks.db` using the `getLightDb()` helper from `@/lib/egx-db`. Due to recent database restructuring, standard stock pricing and volume data resides in `data_engine.db` (queried via `@/lib/data-engine-db`), while `stocks.db` only contains technical metrics (e.g. RSI, support/resistance levels) and lacks the core price columns. This mismatch causes SQL query crashes or returns empty datasets.
2. **Flutter UI State Initialization Bug**: 
   The `StocksScreen` widget in the Flutter app starts asynchronous fetches in `initState` but never populates the `_displayedStocks` list (which the UI actually renders). Furthermore, `_loadMovement()` fetches the top gainers/losers/active classification data but fails to assign it to the `_movementData` state variable, causing the top movers section to remain blank.

---

## 🛠️ Section A: Next.js Backend Fixes (WSL Workspace)

### 1. Dashboard API Route
**File Path**: `src/app/api/mobile/dashboard/route.ts`  
**Problem**: Uses `@/lib/egx-db` to query `stocks.db` which lacks price and volume columns.  
**Solution**: Import from `@/lib/data-engine-db` to query `data_engine.db` and retrieve gold prices / exchange rates from the correct local helpers.

Replace lines **84 to 135** with:
```typescript
    // ─── 5. Top Movers ──────────────────────────────────────────
    let topMovers: any = { gainers: [], losers: [], most_active: [] };
    try {
      const { getTopMovers, getStocksByMarket } = await import('@/lib/data-engine-db');
      
      // Fetch data for the active market (e.g., 'EGX' mapped to Arabic 'مصر' in the lib)
      const movers = getTopMovers('EGX', 5);
      const activeList = getStocksByMarket('EGX', 5);

      topMovers = {
        gainers: movers.gainers.map((s: any) => ({
          ticker: s.symbol,
          name_ar: s.name,
          price: s.price || 0,
          change_percent: s.change_percent || 0,
          volume: parseFloat(s.volume || '0'),
          change_type: 'gainer'
        })),
        losers: movers.losers.map((s: any) => ({
          ticker: s.symbol,
          name_ar: s.name,
          price: s.price || 0,
          change_percent: s.change_percent || 0,
          volume: parseFloat(s.volume || '0'),
          change_type: 'loser'
        })),
        most_active: activeList.map((s: any) => ({
          ticker: s.symbol,
          name_ar: s.name,
          price: s.price || 0,
          change_percent: s.change_percent || 0,
          volume: parseFloat(s.volume || '0')
        }))
      };
    } catch (e) {
      console.warn('[Mobile Dashboard] Top movers error:', e);
    }
```

Also replace the Gold Prices loader (lines **29 to 49**) with:
```typescript
    // ─── 2. Gold Prices ─────────────────────────────────────────
    let goldPrices: any = null;
    try {
      const { getLatestGoldPrices, getLatestSilverPrices } = await import('@/lib/data-engine-db');
      const gold = getLatestGoldPrices();
      const silver = getLatestSilverPrices();

      const egyptGold = gold.filter((g: any) => g.country === 'مصر');
      const egyptSilver = silver.filter((s: any) => s.country === 'مصر');

      if (egyptGold && egyptGold.length > 0) {
        goldPrices = {
          karat_24: egyptGold.find((g: any) => g.karat.includes('24'))?.price_per_gram || egyptGold[0]?.price_per_gram || 0,
          karat_21: egyptGold.find((g: any) => g.karat.includes('21'))?.price_per_gram || 0,
          karat_18: egyptGold.find((g: any) => g.karat.includes('18'))?.price_per_gram || 0,
          change_24k: 0,
          silver: egyptSilver[0]?.price_per_gram || 0,
          last_updated: egyptGold[0]?.timestamp || new Date().toISOString(),
        };
      }
    } catch (e) {
      console.warn('[Mobile Dashboard] Gold prices error:', e);
    }
```

---

### 2. Market Overview API Route
**File Path**: `src/app/api/mobile/market/overview/route.ts`  
**Problem**: Fallback queries `stocks.db` which is empty or missing columns.  
**Solution**: Query `data_engine.db` via `getDataEngineDb()`. Calculate `previous_close` dynamically using the current price and change percent.

Replace lines **45 to 130** with:
```typescript
  // 2. Fallback: Use the data_engine.db database
  try {
    const { getDataEngineDb } = await import('@/lib/data-engine-db');
    const db = getDataEngineDb();

    const stocks = db.prepare(`
      SELECT symbol as ticker, name, price as current_price, change_percent, volume, market
      FROM stocks
      WHERE price > 0
    `).all() as Array<{
      ticker: string;
      name: string;
      current_price: number;
      change_percent: number;
      volume: string | number;
      market: string;
    }>;

    if (stocks.length === 0) {
      return NextResponse.json({
        success: false,
        error: 'No stocks found in database',
      }, { status: 503 });
    }

    let gainers = 0;
    let losers = 0;
    let unchanged = 0;
    const gainersList: any[] = [];
    const losersList: any[] = [];
    const mostActiveList: any[] = [];

    for (const stock of stocks) {
      const changePercent = stock.change_percent || 0;
      const parsedVolume = parseFloat(String(stock.volume || '0'));
      const previousClose = stock.current_price / (1 + changePercent / 100);

      const stockData = {
        ticker: stock.ticker,
        name: stock.name || '',
        name_ar: stock.name || '',
        current_price: stock.current_price,
        change_percent: Math.round(changePercent * 100) / 100,
        volume: parsedVolume,
        previous_close: previousClose
      };

      if (changePercent > 0) {
        gainers++;
        gainersList.push(stockData);
      } else if (changePercent < 0) {
        losers++;
        losersList.push(stockData);
      } else {
        unchanged++;
      }
    }

    gainersList.sort((a, b) => b.change_percent - a.change_percent);
    losersList.sort((a, b) => a.change_percent - b.change_percent);

    const sortedByVolume = [...stocks]
      .map(s => ({ ...s, parsedVolume: parseFloat(String(s.volume || '0')) }))
      .sort((a, b) => b.parsedVolume - a.parsedVolume);

    for (const stock of sortedByVolume.slice(0, 10)) {
      const changePercent = stock.change_percent || 0;
      const previousClose = stock.current_price / (1 + changePercent / 100);
      
      mostActiveList.push({
        ticker: stock.ticker,
        name: stock.name || '',
        name_ar: stock.name || '',
        current_price: stock.current_price,
        change_percent: Math.round(changePercent * 100) / 100,
        volume: stock.parsedVolume,
        previous_close: previousClose
      });
    }
```

---

### 3. Recommendations API Route
**File Path**: `src/app/api/mobile/recommendations/route.ts`  
**Problem**: Fallback queries `stocks.db` which lacks pricing.  
**Solution**: Query `data_engine.db` via `getDataEngineDb()`.

Replace lines **59 to 112** with:
```typescript
    // 2. Fallback to Local DB
    const { getDataEngineDb } = await import('@/lib/data-engine-db');
    const db = getDataEngineDb();

    const stocks = db.prepare(`
      SELECT 
        symbol as ticker, name, name as name_ar, price as current_price, change_percent, volume
      FROM stocks
      WHERE price > 0
    `).all() as Array<{
      ticker: string;
      name: string;
      name_ar: string;
      current_price: number;
      change_percent: number;
      volume: string | number;
    }>;

    // Score each stock
    const scoredStocks = stocks.map(stock => {
      let score = 50;
      const signals: string[] = [];
      const changePercent = stock.change_percent || 0;
      const parsedVolume = parseFloat(String(stock.volume || '0'));

      if (changePercent > 0 && changePercent < 5) {
        score += 15;
        signals.push('positive_momentum');
      } else if (changePercent > 0 && changePercent < 10) {
        score += 10;
        signals.push('moderate_gain');
      } else if (changePercent < 0 && changePercent > -5) {
        score += 5;
        signals.push('slight_dip');
      }

      if (parsedVolume > 1000000) {
        score += 10;
        signals.push('high_liquidity');
      } else if (parsedVolume > 100000) {
        score += 5;
        signals.push('good_liquidity');
      }

      return {
        ...stock,
        score: Math.min(100, Math.max(0, score)),
        change_percent: Math.round(changePercent * 100) / 100,
        signals,
      };
    });
```

---

### 4. Reports API Route
**File Path**: `src/app/api/mobile/reports/route.ts`  
**Problem**: Queries `stocks.db` and uses the old `@/lib/egx-db` gold prices helper.  
**Solution**: Query `data_engine.db` and use `getLatestGoldPrices()` from `@/lib/data-engine-db`.

Replace lines **13 to 30** with:
```typescript
    const { getDataEngineDb, getLatestGoldPrices } = await import('@/lib/data-engine-db');
    const db = getDataEngineDb();

    // Get all stocks from data_engine.db
    const stocks = db.prepare(`
      SELECT 
        symbol as ticker, 
        name as name_ar, 
        price as current_price, 
        change_percent, 
        volume, 
        market_cap
      FROM stocks
      WHERE price > 0
      ORDER BY CAST(market_cap AS REAL) DESC
    `).all() as any[];
```

Also replace the gold prices parser (lines **80 to 94**) with:
```typescript
    // Get gold prices
    let goldData: any = null;
    try {
      const gold = getLatestGoldPrices();
      const egyptGold = gold.filter((g: any) => g.country === 'مصر');
      if (egyptGold && egyptGold.length > 0) {
        goldData = {
          karat_24: egyptGold.find((g: any) => g.karat.includes('24'))?.price_per_gram || egyptGold[0]?.price_per_gram || 0,
          karat_21: egyptGold.find((g: any) => g.karat.includes('21'))?.price_per_gram || 0,
          karat_18: egyptGold.find((g: any) => g.karat.includes('18'))?.price_per_gram || 0,
        };
      }
    } catch (e) {
      console.warn('[Mobile Reports] Gold error:', e);
    }
```

---

### 5. Alerts Check API Route
**File Path**: `src/app/api/mobile/alerts/check/route.ts`  
**Problem**: Selects price data from `stocks.db` which has no current_price column.  
**Solution**: Query `data_engine.db` for prices, and fall back to `stocks.db` for the technical `rsi` metric.

Replace lines **92 to 118** with:
```typescript
    // Fetch live prices and technical indicators
    const { getDataEngineDb, getStocksDb } = await import('@/lib/data-engine-db');
    const dbEngine = getDataEngineDb();
    let dbStocks: any = null;
    try {
      dbStocks = getStocksDb();
    } catch (e) { /* ignore if stocks.db cannot be loaded */ }

    // Tickers to check
    const tickers = [...new Set(alerts.map(a => String(a.ticker)))];
    const prices: Record<string, { current: number; previous: number; rsi: number | null }> = {};

    for (const ticker of tickers) {
      try {
        // Query current price from data_engine.db
        const liveRow = dbEngine.prepare(`
          SELECT price as current_price, change_percent
          FROM stocks
          WHERE symbol = ? COLLATE NOCASE
        `).get(ticker) as { current_price: number; change_percent: number } | undefined;

        // Query RSI from stocks.db
        let rsi: number | null = null;
        if (dbStocks) {
          const technicalRow = dbStocks.prepare(`
            SELECT rsi
            FROM stocks
            WHERE ticker = ? COLLATE NOCASE
          `).get(ticker) as { rsi: number | null } | undefined;
          rsi = technicalRow?.rsi || null;
        }

        if (liveRow) {
          const current = liveRow.current_price || 0;
          const changePercent = liveRow.change_percent || 0;
          const previous = current / (1 + changePercent / 100);

          prices[ticker] = {
            current,
            previous,
            rsi
          };
        }
      } catch (e) {
        console.warn(`[Alerts Check] Error loading ticker ${ticker}:`, e);
      }
    }
```

---

### 6. AI Insights API Route
**File Path**: `src/app/api/mobile/market/recommendations/ai-insights/route.ts`  
**Problem**: Fallback queries `stocks.db` which lacks current_price and volume.  
**Solution**: Query `data_engine.db` via `getDataEngineDb()`.

Replace lines **25 to 40** with:
```typescript
    // 2. Fallback to Local DB
    const { getDataEngineDb } = await import('@/lib/data-engine-db');
    const db = getDataEngineDb();

    // Get market data for analysis from data_engine
    const stocks = db.prepare(`
      SELECT symbol as ticker, price as current_price, change_percent, volume
      FROM stocks
      WHERE price > 0
    `).all() as Array<{
      ticker: string;
      current_price: number;
      change_percent: number;
      volume: string | number;
    }>;
```

Also replace line **60** inside the loop:
```typescript
      const changePercent = stock.change_percent || 0;
      const parsedVolume = parseFloat(String(stock.volume || '0'));
      totalVolume += parsedVolume;
      if (changePercent > 2) bullishCount++;
      else if (changePercent < -2) bearishCount++;
```

---
---

## 📱 Section B: Flutter Frontend Fixes (Local Workspace)

### 1. Stocks Screen State and Classification Rendering
**File Path**: `lib/screens/stocks_screen.dart`  
**Problem**:
- The screen does not assign stocks to `_displayedStocks` in `initState()` or `didUpdateWidget()`, leading to an empty scroll view.
- `_loadMovement()` calls `_fetchMovement` but does not update `_movementData` or set the state.

**Solution**: Update `_loadMovement()` to store the fetched data in `_movementData` and trigger a widget update. Change initialization calls to use `_loadStocks()` instead of assigning `_stocksFuture` directly without populating display lists.

#### Replacement Chunk 1 (State Initialization):
Replace `initState` (lines **72 to 80**) with:
```dart
  @override
  void initState() {
    super.initState();
    _loadActiveMarket().then((_) {
      _loadStocks(_query);
      _loadMovement();
    });
  }
```

#### Replacement Chunk 2 (Widget Updates):
Replace `didUpdateWidget` (lines **82 to 92**) with:
```dart
  @override
  void didUpdateWidget(covariant StocksScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.marketVersion != widget.marketVersion) {
      _loadActiveMarket().then((_) {
        _loadStocks(_query);
        _loadMovement();
      });
    }
  }
```

#### Replacement Chunk 3 (Movement Fetching):
Replace `_loadMovement` (lines **155 to 158**) with:
```dart
  Future<void> _loadMovement() async {
    final data = await _fetchMovement(_activeMarket);
    if (mounted) {
      setState(() {
        _movementData = data;
      });
    }
  }
```

---

## 🚦 Verification
To verify the fixes:
1. **Next.js Server**: Run curl requests on endpoints:
   - `curl http://localhost:3000/api/mobile/dashboard`
   - `curl http://localhost:3000/api/mobile/market/overview`
   Check that `top_movers`, `gold_prices`, and `currency_rates` are fully populated.
2. **Flutter App**: Run `flutter analyze` to ensure clean compilation. When running in the emulator, the main dashboard and stocks screener tabs will now display the Egyptian and international market statistics instantly.
