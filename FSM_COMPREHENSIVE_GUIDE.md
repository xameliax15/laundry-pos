# 🎯 FINITE STATE MACHINE (FSM) - Laundry POS Application

## ✅ **YES - APLIKASI MENGGUNAKAN FINITE STATE MACHINE!**

Aplikasi ini **sudah mengimplementasikan FSM formal** untuk mengelola transaction state dengan state transitions yang ketat.

---

## 1. 📍 LOKASI FSM

**File**: `lib/core/transaction_fsm.dart` (305 lines)
**Status**: ✅ Fully implemented
**Integration**: Ready to use in TransaksiService

---

## 2. 🏗️ FSM STRUCTURE

### 2.1 States Defined

```
enum TransactionState {
  pending,      // Menunggu untuk diproses
  proses,       // Sedang dalam proses pencucian
  selesai,      // Siap untuk dikirim/diambil
  dikirim,      // Sedang dalam pengiriman (delivery only)
  diterima,     // Pesanan telah diterima [FINAL STATE]
}
```

### 2.2 Events Defined

```
enum TransactionEvent {
  mulaiProses,   // Event: Mulai proses pencucian
  selesaikan,    // Event: Selesaikan pencucian
  kirim,         // Event: Kirim pesanan (delivery)
  terima,        // Event: Terima pesanan
  ambil,         // Event: Ambil pesanan (pickup)
}
```

---

## 3. 🔄 STATE TRANSITION DIAGRAM

### For Delivery Transactions (`isDelivery: true`)

```
┌─────────┐
│ PENDING │ (awal)
└────┬────┘
     │ mulaiProses
     ▼
┌─────────┐
│ PROSES  │ (dalam proses)
└────┬────┘
     │ selesaikan
     ▼
┌─────────┐
│ SELESAI │
└────┬────┬──────────────┐
     │    │              │
     │ kirim            │ terima (skip dikirim)
     │    │              │
     ▼    ▼              │
┌──────────┐             │
│ DIKIRIM  │─────────────┤
└────┬─────┘             │
     │ terima            │
     └────────┬──────────┘
              ▼
         ┌──────────┐
         │ DITERIMA │ (final) ✓
         └──────────┘
```

### For Pickup Transactions (`isDelivery: false`)

```
┌─────────┐
│ PENDING │ (awal)
└────┬────┘
     │ mulaiProses
     ▼
┌─────────┐
│ PROSES  │ (dalam proses)
└────┬────┘
     │ selesaikan
     ▼
┌─────────┐
│ SELESAI │ (siap diambil)
└────┬────┘
     │ ambil
     ▼
┌──────────┐
│ DITERIMA │ (final) ✓
└──────────┘
```

---

## 4. 📋 TRANSITION TABLE

### Delivery Transactions

| Current State | Event | Next State | Valid? |
|---|---|---|---|
| **pending** | mulaiProses | proses | ✅ |
| **pending** | selesaikan | - | ❌ |
| **proses** | selesaikan | selesai | ✅ |
| **proses** | terima | - | ❌ |
| **selesai** | kirim | dikirim | ✅ |
| **selesai** | terima | diterima | ✅ (flexible) |
| **selesai** | ambil | - | ❌ |
| **dikirim** | terima | diterima | ✅ |
| **dikirim** | kirim | - | ❌ |
| **diterima** | (none) | - | ❌ (final state) |

### Pickup Transactions

| Current State | Event | Next State | Valid? |
|---|---|---|---|
| **pending** | mulaiProses | proses | ✅ |
| **proses** | selesaikan | selesai | ✅ |
| **selesai** | ambil | diterima | ✅ |
| **diterima** | (none) | - | ❌ (final state) |

---

## 5. 🛠️ FSM CLASS STRUCTURE

### Main Class: `TransactionFSM`

```dart
class TransactionFSM {
  final bool isDelivery;              // Jenis transaksi
  TransactionState _currentState;     // State internal

  // Getters
  TransactionState get currentState
  List<TransactionEvent> getAvailableEvents()
  List<TransactionState> getNextStates()
  bool get isFinalState

  // Methods
  bool processEvent(TransactionEvent event)           // Process event
  bool canTransitionTo(TransactionState target)       // Check valid
  bool transitionTo(TransactionState target)          // Direct transition
  
  // Utilities
  static TransactionState fromString(String status)
  static String stateToString(TransactionState state)
  String getStateDescription()
  TransactionFSM clone()
}
```

### Extended Class: `TransactionFSMWithActions`

```dart
class TransactionFSMWithActions extends TransactionFSM {
  final TransactionFSMActions? actions;
  
  // Async version dengan lifecycle callbacks
  Future<bool> processEventAsync(TransactionEvent event)
}
```

### Callback Interface: `TransactionFSMActions`

```dart
abstract class TransactionFSMActions {
  Future<bool> onBeforeTransition(...)   // Validate sebelum transisi
  Future<void> onAfterTransition(...)    // Update data setelah transisi
  Future<void> onTransitionFailed(...)   // Handle error saat transisi gagal
}
```

---

## 6. 💡 USAGE EXAMPLES

### Basic Usage (Sync)

```dart
// Create FSM
var fsm = TransactionFSM(
  initialState: TransactionState.pending,
  isDelivery: true,
);

// Check available events
List<TransactionEvent> events = fsm.getAvailableEvents();
// Output: [TransactionEvent.mulaiProses]

// Process event
bool success = fsm.processEvent(TransactionEvent.mulaiProses);
// Result: true, currentState = proses

// Check next valid states
List<TransactionState> nextStates = fsm.getNextStates();
// Output: [TransactionState.selesai]

// Check if can transition
bool canGoDikirim = fsm.canTransitionTo(TransactionState.dikirim);
// Result: false (not valid from proses)
```

### Advanced Usage (Async with Actions)

```dart
// Create FSM with actions
var fsm = TransactionFSMWithActions(
  initialState: TransactionState.pending,
  isDelivery: true,
  actions: MyTransactionFSMActions(),
);

// Process event with lifecycle
bool success = await fsm.processEventAsync(TransactionEvent.mulaiProses);

// Callbacks triggered:
// 1. onBeforeTransition (validate)
// 2. Process event (change state)
// 3. onAfterTransition (update database)
// or
// onTransitionFailed (if validation fails)
```

### Validation Example

```dart
// Cek apakah transaksi bisa naik status
bool canUpdateStatus = fsm.canTransitionTo(TransactionState.dikirim);

if (canUpdateStatus) {
  // Update diizinkan
  fsm.transitionTo(TransactionState.dikirim);
  await transaksiService.updateStatus(transaksiId, 'dikirim');
} else {
  // Update ditolak
  showError('Transaksi tidak bisa dikirim dari status: ${fsm.currentState}');
}
```

---

## 7. 🔒 BENEFITS OF FSM

### Sebelum FSM (Manual Validation)
```dart
// Validasi manual - bisa inconsistent
if (currentStatus == 'pending' && newStatus == 'selesai') {
  // ❌ Melompati 'proses' - not allowed!
  updateStatus(newStatus);
}

// Berbeda tempat - sulit maintain
if (userRole == 'kasir') {
  if (status == 'pending') {
    // ... multiple if checks
  }
}
```

### Sesudah FSM (Formal Validation)
```dart
// Validasi formal - konsisten dan terpusat
var fsm = TransactionFSM(initialState: TransactionState.pending);

bool canUpdate = fsm.canTransitionTo(TransactionState.selesai);
// ✅ Returns false - transition tidak valid!

// Semua logic di satu tempat
List<TransactionEvent> validEvents = fsm.getAvailableEvents();
// ✅ Returns [mulaiProses] - hanya event valid
```

### Key Benefits:
1. ✅ **Formal Validation** - State transitions terjaga ketat
2. ✅ **Centralized Logic** - Semua transisi di satu tempat
3. ✅ **Type Safe** - Enum-based (compile-time checking)
4. ✅ **Flexibility** - Support both delivery & pickup flows
5. ✅ **Extensible** - Actions/callbacks untuk custom logic
6. ✅ **Maintainable** - Mudah menambah/modify transitions
7. ✅ **Testable** - Unit test FSM logic terisolasi

---

## 8. 📊 IMPLEMENTATION STATUS

### ✅ Implemented
- [x] FSM core class (`TransactionFSM`)
- [x] State & Event enums
- [x] Transition table (both delivery & pickup)
- [x] State validation methods
- [x] String conversion (for DB storage)
- [x] Extended FSM with actions (`TransactionFSMWithActions`)
- [x] Comprehensive documentation

### ⏳ Integration Pending
- [ ] Use FSM in `TransaksiService.updateStatus()`
- [ ] Use FSM for transaction state UI updates
- [ ] Add FSM validation in Kasir Dashboard
- [ ] Add FSM validation in Owner Dashboard
- [ ] Add FSM validation in Kurir Dashboard

---

## 9. 🔌 INTEGRATION POINTS

### Where FSM Should Be Used

#### 1. **TransaksiService** (Main Integration)
```dart
Future<bool> updateStatus(String transaksiId, String newStatus) async {
  // Current: Direct update
  
  // Should be: FSM-based update
  var fsm = TransactionFSM(
    initialState: currentState,
    isDelivery: transaksi.isDelivery,
  );
  
  if (fsm.canTransitionTo(TransactionState.fromString(newStatus))) {
    // Valid transition
    await db.update(...);
    return true;
  } else {
    // Invalid transition
    throw InvalidTransitionException(...);
  }
}
```

#### 2. **Kasir Dashboard** (UI Buttons)
```dart
// Show only valid status change buttons
List<TransactionEvent> validEvents = fsm.getAvailableEvents();

for (var event in validEvents) {
  // Create button for each valid event
  ElevatedButton(
    label: TransactionFSM.getEventDescription(event),
    onPressed: () => updateStatus(event),
  );
}
```

#### 3. **Owner Dashboard** (Status Monitoring)
```dart
// Show current status & available next states
Text(fsm.getStateDescription())  // "Sedang dalam proses pencucian"

// Show progress to final state
LinearProgressIndicator(
  value: fsm.currentState.index / TransactionState.values.length,
)
```

#### 4. **Kurir Dashboard** (Delivery Tracking)
```dart
// Only show 'kirim' & 'terima' for kurir
if (fsm.currentState == TransactionState.selesai) {
  // Kurir can mark as dikirim
  showKirimButton();
} else if (fsm.currentState == TransactionState.dikirim) {
  // Kurir can mark as diterima
  showTerimaButton();
}
```

---

## 10. 🧪 TESTING FSM

### Unit Test Examples

```dart
test('FSM delivery: pending -> proses -> selesai -> dikirim -> diterima', () {
  var fsm = TransactionFSM(
    initialState: TransactionState.pending,
    isDelivery: true,
  );
  
  expect(fsm.processEvent(TransactionEvent.mulaiProses), true);
  expect(fsm.currentState, TransactionState.proses);
  
  expect(fsm.processEvent(TransactionEvent.selesaikan), true);
  expect(fsm.currentState, TransactionState.selesai);
  
  expect(fsm.processEvent(TransactionEvent.kirim), true);
  expect(fsm.currentState, TransactionState.dikirim);
  
  expect(fsm.processEvent(TransactionEvent.terima), true);
  expect(fsm.currentState, TransactionState.diterima);
  expect(fsm.isFinalState, true);
});

test('FSM prevents invalid transition', () {
  var fsm = TransactionFSM(
    initialState: TransactionState.pending,
    isDelivery: true,
  );
  
  // Try to skip proses state
  expect(fsm.processEvent(TransactionEvent.selesaikan), false);
  expect(fsm.currentState, TransactionState.pending); // Unchanged
});

test('FSM getAvailableEvents returns correct events', () {
  var fsm = TransactionFSM(
    initialState: TransactionState.pending,
    isDelivery: true,
  );
  
  var events = fsm.getAvailableEvents();
  expect(events, [TransactionEvent.mulaiProses]);
  expect(events.contains(TransactionEvent.selesaikan), false);
});
```

---

## 11. 📈 FSM COMPLEXITY ANALYSIS

### Time Complexity
- `processEvent()`: **O(1)** - Direct lookup in transition table
- `getAvailableEvents()`: **O(1)** - Return transition keys
- `canTransitionTo()`: **O(1)** - Check if state in values
- `processEventAsync()`: **O(1)** + async callbacks

### Space Complexity
- **O(1)** - Transition table is static (not growing)
- **O(states)** for storing state descriptions
- **O(events)** for storing event descriptions

### Why FSM is Efficient
1. ✅ Constant-time lookups (transition table is pre-defined)
2. ✅ No dynamic allocation (enum-based)
3. ✅ No string parsing (uses enum directly)
4. ✅ No database queries (all in memory)

---

## 12. 🚀 NEXT STEPS

### Priority 1: Integration (Short-term)
- [ ] Use FSM in `TransaksiService.updateStatus()`
- [ ] Add FSM validation in status update dialogs
- [ ] Add error handling for invalid transitions
- [ ] Update UI to show only valid state transitions

### Priority 2: Enhancement (Medium-term)
- [ ] Implement `TransactionFSMActions` callbacks
- [ ] Add async state transition with database updates
- [ ] Add FSM event logging
- [ ] Add FSM state history tracking

### Priority 3: Monitoring (Long-term)
- [ ] Add FSM metrics (state distribution, common paths)
- [ ] Add FSM analytics (transition duration, bottlenecks)
- [ ] Add FSM visualization (state diagram in admin dashboard)
- [ ] Add FSM alerts (stuck transactions, unusual flows)

---

## 13. 📚 REFERENCE IMPLEMENTATION

The FSM is already implemented and ready to use. Example usage in TransaksiService:

```dart
// lib/core/transaction_fsm.dart - Already exists!
var fsm = TransactionFSM(
  initialState: TransactionState.pending,
  isDelivery: transaksi.isDelivery ?? false,
);

// Check valid transitions before update
if (fsm.canTransitionTo(newState)) {
  fsm.transitionTo(newState);
  // Update database with new status
}
```

---

## 14. ✨ SUMMARY

| Aspek | Status | Detail |
|---|---|---|
| **FSM Implemented?** | ✅ YES | `transaction_fsm.dart` - fully implemented |
| **States Defined** | ✅ 5 states | pending, proses, selesai, dikirim, diterima |
| **Events Defined** | ✅ 5 events | mulaiProses, selesaikan, kirim, terima, ambil |
| **Transition Table** | ✅ Formal | Defined for both delivery & pickup |
| **Type Safety** | ✅ Enum-based | Compile-time checking |
| **Extensibility** | ✅ Actions support | Async callbacks available |
| **Integration** | ⏳ Pending | Ready to integrate in TransaksiService |
| **Testing** | ⏳ Pending | FSM logic testable, unit tests needed |
| **Documentation** | ✅ Complete | Full documentation available |

