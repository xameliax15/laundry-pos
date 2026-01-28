# 🔬 ALGORITHMS & BUSINESS LOGIC - Laundry POS Application

## 1. 🏆 MAIN ALGORITHMS

### 1.1 Price Calculation Algorithm (Switch-Case Nested)
**Lokasi**: `lib/core/price_list.dart` - `getHarga()`
**Time Complexity**: O(1) - Constant time (direct lookup)
**Space Complexity**: O(1)

```
Algorithm: Price Lookup with Multi-level Criteria
- Input: jenisLayanan, jenisBarang, ukuran, berat, luas
- Process: 
  1. Switch on jenisLayanan (7 cases)
  2. For each service, switch on jenisBarang/ukuran
  3. Calculate: basePrice × quantity (berat/luas)
- Output: Final price (Rp)

Supported Service Types:
├── Laundry Kiloan (weight-based: berat × hargaPerKg)
│   ├── Reguler: 6.000/kg
│   ├── Semi-Quick: 6.500/kg  
│   ├── Quick: 7.500/kg
│   ├── Express: 10.000/kg
│   ├── Super-Express: 15.000/kg
│   ├── Setrika Saja: 4.500/kg
│   └── Cuci Lipat: 5.000/kg (min 1kg)
├── Sepatu (fixed price)
│   ├── Sneakers: 20.000
│   └── Kulit: 25.000
├── Jaket (fixed price)
│   └── Kulit: 30.000
├── Helm: 20.000 (fixed)
├── Tas (size-based: fixed per size)
│   ├── Kecil: 15.000
│   ├── Sedang: 20.000
│   ├── Besar: 25.000
│   └── Carrier: 50.000
├── Boneka (size-based: fixed per size)
│   ├── Kecil: 15.000
│   ├── Sedang: 20.000
│   ├── Besar: 35.000
│   └── Jumbo: 50.000
└── Karpet (area-based: luas × hargaPerM²)
    ├── Standar: 13.000/m²
    ├── Tipis: 10.000/m²
    └── Tebal/Mushola: 15.000/m²
```

**Code Pattern**:
```dart
// Linear Search with Nested Switch
static double getHarga({
  required String jenisLayanan,
  required String jenisBarang,
  String? ukuran,
  double? berat,
  double? luas,
}) {
  switch (jenisLayanan) {  // First level: O(1)
    case 'laundry_kiloan':
      switch (jenisBarang) {  // Second level: O(1)
        case 'reguler':
          return laundryReguler * (berat ?? minKiloan);
        // ...
      }
    // ...
  }
}
```

---

### 1.2 Transaction Search Algorithm
**Lokasi**: `lib/services/transaksi_service.dart` - `searchTransaksi()`
**Type**: Full-text search or SQL LIKE query
**Time Complexity**: O(n) - Linear scan through results
**Space Complexity**: O(n) - Results stored in memory

```
Algorithm: Database Query Filter
- Input: Search query string
- Process:
  1. Execute Supabase query with LIKE/ILIKE filter
  2. Search across: invoice_number, customer_name, phone
  3. Return filtered transactions
- Output: List<Transaksi> matching criteria
```

**Usage**:
```dart
// Provider method in TransaksiProvider
Future<void> searchTransaksi(String query) async {
  final results = await _transaksiService.searchTransaksi(query);
  _transaksi = results;
  notifyListeners();
}
```

---

### 1.3 Transaction Status Filter Algorithm
**Lokasi**: `lib/services/transaksi_service.dart` - `getTransaksiByStatus()`
**Type**: Equality filter
**Time Complexity**: O(n) - Database index scan
**Space Complexity**: O(n) - Results loaded in memory

```
Algorithm: Status-based Filtering
- Input: Status string (pending|proses|selesai|dikirim|diterima)
- Process:
  1. Query database: WHERE status = ?
  2. Use indexed column for fast lookup
  3. Sort by date (newest first)
- Output: List<Transaksi> with matching status
```

**Valid Status Values**:
- `pending` - Belum diproses
- `proses` - Sedang diproses
- `selesai` - Selesai diproses
- `dikirim` - Sedang dikirim kurir
- `diterima` - Diterima customer

---

### 1.4 Today's Transactions Filter
**Lokasi**: `lib/services/transaksi_service.dart` - `getTransaksiHariIni()`
**Type**: Date range query
**Time Complexity**: O(n) where n = transactions today
**Space Complexity**: O(n)

```
Algorithm: Date-based Range Query
- Input: Current date (DateTime.now())
- Process:
  1. Calculate: startOfDay (00:00:00)
  2. Calculate: endOfDay (23:59:59)
  3. Query: WHERE created_at >= startOfDay AND created_at <= endOfDay
- Output: List<Transaksi> created today
```

---

## 2. 💾 DATA PERSISTENCE ALGORITHMS

### 2.1 Local Caching Strategy
**Lokasi**: `lib/database/local_db.dart`
**Type**: Key-value cache (SharedPreferences wrapper)
**Time Complexity**: O(1) - Direct key lookup
**Space Complexity**: O(n) - Limited by SharedPreferences

```
Algorithm: Preference Caching
- Input: Key, Value
- Process:
  1. Store in SharedPreferences
  2. Retrieve on app start
  3. Update on data change
- Output: Persisted user data

Cached Items:
├── User profile (AuthProvider)
├── Auth token
├── App preferences
├── Last searched query
└── UI state (theme, etc.)
```

### 2.2 SQLite Offline Sync (Planned)
**Type**: Bidirectional sync algorithm
**Time Complexity**: O(n log n) - Merge sort for sync
**Space Complexity**: O(n)

```
Algorithm: Offline-First Sync Pattern (Future Implementation)
- Input: Local SQLite data + Remote Supabase data
- Process:
  1. Check local transactions (offline)
  2. Check remote transactions (online)
  3. Merge: Keep newest timestamp
  4. Resolve conflicts: Last-write-wins
  5. Sync: Upload local → remote
  6. Sync: Download remote → local
- Output: Unified transaction list
```

---

## 3. 🔐 AUTHENTICATION ALGORITHM

### 3.1 Credentials Validation (Supabase JWT)
**Lokasi**: `lib/services/auth_service.dart` - `login()`
**Type**: Credential verification with token generation
**Time Complexity**: O(1) - Database lookup + JWT generation
**Space Complexity**: O(1)

```
Algorithm: Email-Password Authentication
- Input: username, password
- Process:
  1. Resolve username → email (query DB)
  2. Normalize email (lowercase, trim)
  3. Call Supabase auth.signInWithPassword()
  4. Supabase returns JWT token + user object
  5. Fetch user profile from DB
  6. Cache token in SharedPreferences
  7. Log activity in database
- Output: User object with role

Token Format: JWT (JSON Web Token)
- Header: Algorithm (HS256)
- Payload: User ID, email, role, issued_at, expires_at
- Signature: Server-signed
```

### 3.2 Email Resolution Algorithm
**Lokasi**: `lib/services/auth_service.dart` - `_resolveEmail()`
**Type**: Username → Email lookup
**Time Complexity**: O(1) - Indexed database query
**Space Complexity**: O(1)

```
Algorithm: Username to Email Conversion
- Input: Username or Email string
- Process:
  1. Check if input is valid email format
  2. If email: return normalized email
  3. If username: query DB for associated email
  4. Return email or null
- Output: Valid email string or null
```

---

## 4. 📊 REPORTING & STATISTICS ALGORITHMS

### 4.1 Daily Revenue Calculation
**Lokasi**: `lib/pages/owner/owner_dashboard.dart` (implied)
**Type**: Aggregation + summation
**Time Complexity**: O(n) - Sum all transactions
**Space Complexity**: O(1)

```
Algorithm: Revenue Sum
- Input: List<Transaksi> for today
- Process:
  1. Filter: WHERE status = 'selesai' AND paid = true
  2. Sum: total_price for all matching
  3. Format: Currency (Rp)
- Output: Double (total revenue)
```

### 4.2 Transaction Count By Status
**Type**: Grouping + counting
**Time Complexity**: O(n)
**Space Complexity**: O(k) where k = number of statuses

```
Algorithm: Status Distribution Count
- Input: List<Transaksi>
- Process:
  1. Initialize counters for each status
  2. Iterate through transactions
  3. Increment counter for each status
  4. Calculate percentages
- Output: Map<Status, Count>
```

---

## 5. 🎯 FORM VALIDATION ALGORITHMS

### 5.1 Input Validation
**Type**: Sequential validation checks
**Time Complexity**: O(1) - Fixed number of checks
**Space Complexity**: O(1)

```
Algorithm: Multi-field Validation
- Input: Form data
- Process:
  1. Check field not empty
  2. Check field length (min/max)
  3. Check format (email, number, etc.)
  4. Check business rules (e.g., weight >= minKiloan)
  5. Return validation result
- Output: Boolean (valid) + Error message
```

### 5.2 Weight Validation (Decimal Support)
**Lokasi**: `lib/pages/kasir/kasir_dashboard.dart` (line 1480)
**Type**: Numeric range validation
**Time Complexity**: O(1)
**Space Complexity**: O(1)

```
Algorithm: Weight Decimal Parsing & Validation
- Input: String (user input)
- Process:
  1. Parse as double: double.tryParse(value)
  2. Check >= minKiloan (usually 1.0)
  3. If below minimum: use minimum value
  4. Otherwise: use parsed value
  5. Update model and recalculate price
- Output: Double (validated weight) or minimum value
```

---

## 6. 🔄 STATE MANAGEMENT ALGORITHMS

### 6.1 Provider Pattern (Reactive State)
**Lokasi**: `lib/providers/app_providers.dart`
**Type**: Observer pattern + notifyListeners()
**Time Complexity**: O(n) where n = listeners
**Space Complexity**: O(n)

```
Algorithm: Observer Pattern Implementation
- Input: State change (new transaction, login, etc.)
- Process:
  1. Update internal state variable
  2. Call notifyListeners()
  3. Flutter rebuilds all listening widgets
  4. Only affected widgets re-render
- Output: Updated UI (automatic)

Providers:
├── AuthProvider
│   ├── State: currentUser, isLoggedIn
│   └── Methods: login(), logout(), refreshUser()
└── TransaksiProvider
    ├── State: transaksiList, filter, search
    └── Methods: load(), filter(), search(), refresh()
```

---

## 7. 🎨 UI RENDERING ALGORITHMS

### 7.1 Responsive Layout Algorithm
**Lokasi**: `lib/widgets/sidebar_layout.dart`
**Type**: Breakpoint-based conditional rendering
**Time Complexity**: O(1) - Single device check
**Space Complexity**: O(1)

```
Algorithm: Responsive Design Breakpoints
- Input: Screen width (MediaQuery.of(context).size.width)
- Process:
  1. Check if width > 900px (desktop)
  2. If true: show sidebar + content side-by-side
  3. If false: show mobile/tablet layout
  4. Adjust spacing using AppDimensions constants
- Output: Optimized layout for device

Breakpoints (AppBreakpoints):
├── mobile: 480px
├── tablet: 768px
├── desktop: 1024px
└── ultraWide: 1440px
```

### 7.2 Skeleton Loader Animation
**Lokasi**: `lib/widgets/skeleton_loader.dart`
**Type**: Shimmer animation with periodic update
**Time Complexity**: O(1) per frame
**Space Complexity**: O(1)

```
Algorithm: Shimmer Loading Animation
- Input: AnimationController (1500ms duration)
- Process:
  1. Create linear gradient
  2. Animate gradient position (0 → 1 → 0)
  3. Update every frame (60fps)
  4. Apply ShaderMask to create shimmer effect
  5. Show until real data loads
- Output: Animated loading placeholder

Pattern:
  Animation value: 0.0 ──→ 1.0
  Gradient position:  ←Light──Dark──Light→
```

---

## 8. 🔍 SEARCH & SORT ALGORITHMS

### 8.1 Linear Search (Database Query)
**Type**: SQL LIKE filter
**Time Complexity**: O(n) - Full table scan
**Space Complexity**: O(k) - Results only

```
SQL Query Pattern:
SELECT * FROM transaksi 
WHERE invoice_number ILIKE ? 
   OR customer_name ILIKE ?
   OR phone ILIKE ?
```

### 8.2 Sorting (Database Order By)
**Type**: Index-based sort (if indexed)
**Time Complexity**: O(n log n) - Merge sort or index scan
**Space Complexity**: O(n)

```
SQL Query Pattern:
SELECT * FROM transaksi 
WHERE status = ?
ORDER BY created_at DESC
LIMIT 20

Typical sort keys:
├── created_at (newest first)
├── total_price (highest first)
├── customer_name (A-Z)
└── status (predefined order)
```

---

## 9. 📱 MOBILE OPTIMIZATION ALGORITHMS

### 9.1 Image Picker Optimization
**Lokasi**: Implicit in image_picker package
**Type**: Memory-efficient image loading
**Time Complexity**: O(image_size)
**Space Complexity**: O(image_size)

```
Algorithm: Image Selection & Upload
- Input: User selects image from gallery/camera
- Process:
  1. Compress image (quality reduction)
  2. Resize to max 1024x1024 (if needed)
  3. Convert to JPEG/PNG
  4. Upload to Supabase Storage
  5. Store URL in database
- Output: Image URL reference
```

---

## 10. 🛡️ DATA VALIDATION ALGORITHMS

### 10.1 Transaction Data Validation
**Type**: Multi-stage validation
**Time Complexity**: O(k) where k = number of fields
**Space Complexity**: O(1)

```
Algorithm: Transaction Integrity Check
- Input: Transaction object
- Process:
  1. Check customer exists
  2. Check all items have valid service type
  3. Check prices are calculated correctly
  4. Check required fields not null
  5. Check total_price = sum(item prices)
  6. Check payment status valid
- Output: Valid flag + Error list
```

---

## 11. 📊 SUMMARY TABLE

| Algorithm | Location | Type | Time | Space | Usage |
|-----------|----------|------|------|-------|-------|
| Price Calculation | PriceList.getHarga() | Switch-Case | O(1) | O(1) | Every transaction |
| Search Transaksi | TransaksiService | DB Query | O(n) | O(n) | Search feature |
| Filter by Status | TransaksiService | DB Index | O(n) | O(n) | Dashboard |
| Today's Trans. | TransaksiService | Date Query | O(n) | O(n) | Daily report |
| Authentication | AuthService | JWT | O(1) | O(1) | Login |
| Email Resolution | AuthService | DB Lookup | O(1) | O(1) | Login |
| Cache Storage | LocalDB | Key-Value | O(1) | O(n) | Offline support |
| State Management | Provider | Observer | O(n) | O(n) | UI Updates |
| Responsive Layout | SidebarLayout | Breakpoint | O(1) | O(1) | Screen change |
| Skeleton Animation | SkeletonLoader | Periodic | O(1) | O(1) | Loading state |
| Revenue Sum | Owner Dashboard | Aggregation | O(n) | O(1) | Statistics |

---

## 12. 🚀 OPTIMIZATION NOTES

### Current Optimizations:
- ✅ **Database indexing** (Supabase primary keys)
- ✅ **SQLite local caching** (offline support)
- ✅ **Provider lazy loading** (avoid unnecessary rebuilds)
- ✅ **Image compression** (memory efficient)
- ✅ **Constant-time price lookup** (switch-case)

### Potential Improvements (Phase 2-3):
- 🔄 **Implement pagination** - Limit results (O(1) per page)
- 🔄 **Add database indexing** - Speed up search (O(log n))
- 🔄 **Implement caching layer** - Redis/Memcached equivalent
- 🔄 **Batch operations** - Reduce API calls
- 🔄 **Debounced search** - Reduce DB load
- 🔄 **Lazy loading** - Load items on scroll

---

## 13. 🔧 ALGORITHMIC PATTERNS USED

1. **Switch-Case Pattern** - Price lookup, status handling
2. **Observer Pattern** - Provider state management
3. **Strategy Pattern** - Different pricing strategies per service
4. **Template Method** - Validation pipeline
5. **Adapter Pattern** - Supabase ↔ LocalDB sync
6. **Factory Pattern** - Service instantiation
7. **Singleton Pattern** - AuthService, PriceList
8. **Decorator Pattern** - Shimmer effect on skeleton
9. **Repository Pattern** - Services layer abstraction

