# Dokumentasi Integrasi FSM ke TransaksiService

## ✅ Integrasi Selesai!

FSM (Finite State Machine) telah berhasil diintegrasikan ke `TransaksiService` untuk menggantikan validasi Map-based.

---

## 📋 Perubahan yang Dilakukan

### 1. **Import FSM**
```dart
import '../core/transaction_fsm.dart';
```

### 2. **Update Method `updateStatusTransaksi()`**

**Sebelum (Map-based validation):**
```dart
final validTransitions = {
  'pending': ['proses'],
  'proses': ['selesai'],
  'selesai': ['dikirim', 'diterima'],
  'dikirim': ['diterima'],
  'diterima': [],
};

if (!validTransitions.containsKey(currentStatus) ||
    !validTransitions[currentStatus]!.contains(newStatus)) {
  throw Exception('Invalid transition');
}
```

**Sesudah (FSM-based validation):**
```dart
final fsm = TransactionFSM(
  initialState: TransactionFSM.fromString(transaksi.status),
  isDelivery: transaksi.isDelivery,
);

final targetState = TransactionFSM.fromString(newStatus);
if (!fsm.canTransitionTo(targetState)) {
  throw Exception('Invalid transition');
}

// Lakukan transisi di FSM
fsm.transitionTo(targetState);
```

### 3. **Helper Methods Baru**

#### a. `getAvailableNextStates()`
Mendapatkan list status berikutnya yang valid untuk state saat ini:
```dart
List<String> getAvailableNextStates(String currentStatus, bool isDelivery)
```

**Contoh penggunaan:**
```dart
final nextStates = _transaksiService.getAvailableNextStates(
  'proses', 
  false // isDelivery
);
// Returns: ['selesai']
```

#### b. `getAvailableEvents()`
Mendapatkan list event yang valid untuk state saat ini (event-driven approach):
```dart
List<String> getAvailableEvents(String currentStatus, bool isDelivery)
```

**Contoh penggunaan:**
```dart
final events = _transaksiService.getAvailableEvents(
  'proses',
  false
);
// Returns: ['selesaikan']
```

#### c. `canTransitionTo()`
Validasi apakah transisi dari state saat ini ke state target valid:
```dart
bool canTransitionTo(String currentStatus, String newStatus, bool isDelivery)
```

**Contoh penggunaan:**
```dart
final isValid = _transaksiService.canTransitionTo(
  'proses',
  'selesai',
  false
);
// Returns: true
```

---

## ✅ Keuntungan Integrasi FSM

### 1. **Validasi Formal dan Terstruktur**
- FSM memberikan validasi yang lebih formal
- State dan transisi didefinisikan secara eksplisit
- Tidak ada ambigu dalam validasi

### 2. **Event-Driven Architecture (Optional)**
- Bisa menggunakan event-based approach
- Lebih intuitif: "apa yang terjadi" bukan "kemana perginya"
- Memudahkan logging dan auditing

### 3. **Konsistensi**
- Validasi konsisten di seluruh aplikasi
- Helper methods memudahkan UI untuk mendapatkan next states
- Tidak perlu duplikasi logic validasi

### 4. **Maintainability**
- Mudah untuk menambahkan state/event baru
- Perubahan validasi hanya di satu tempat (FSM)
- Dokumentasi jelas dengan state diagram

### 5. **Testability**
- FSM bisa di-test secara terpisah
- Unit test untuk setiap transisi
- Integration test lebih mudah

---

## 🔄 Backward Compatibility

### ✅ **Tidak Ada Breaking Changes!**

- **Method signature tetap sama**: `updateStatusTransaksi()` tidak berubah
- **Return value tetap sama**: Masih mengembalikan `Transaksi`
- **Error handling tetap sama**: Masih throw `Exception` dengan message yang sama
- **Behavior tetap sama**: Jalur transaksi tetap sama persis

### ⚠️ **Yang Berubah Hanya:**

- **Implementasi validasi**: Dari Map-based ke FSM-based
- **Tidak terlihat dari luar**: UI dan kode lain tidak perlu diubah

---

## 📝 Contoh Penggunaan

### **Update Status (Sama Seperti Sebelumnya)**
```dart
try {
  final updated = await _transaksiService.updateStatusTransaksi(
    transaksiId,
    'selesai',
    kurirId: kurirId,
    isDelivery: isDelivery,
  );
  // Success!
} catch (e) {
  // Error handling
}
```

### **Get Available Next States (Baru)**
```dart
// Untuk UI yang ingin menampilkan dropdown status
final nextStates = _transaksiService.getAvailableNextStates(
  transaksi.status,
  transaksi.isDelivery,
);

// nextStates: ['selesai'] jika status saat ini 'proses'
```

### **Validate Before Update (Baru)**
```dart
// Validasi sebelum update
if (_transaksiService.canTransitionTo(
  transaksi.status,
  'selesai',
  transaksi.isDelivery,
)) {
  // Update status
  await _transaksiService.updateStatusTransaksi(...);
} else {
  // Show error: transisi tidak valid
}
```

---

## 🧪 Testing

### **Unit Test untuk FSM**
```dart
test('FSM validasi transisi pickup', () {
  final fsm = TransactionFSM(
    initialState: TransactionState.proses,
    isDelivery: false,
  );
  
  expect(fsm.canTransitionTo(TransactionState.selesai), true);
  expect(fsm.canTransitionTo(TransactionState.diterima), false);
});
```

### **Integration Test untuk TransaksiService**
```dart
test('updateStatusTransaksi menggunakan FSM', () async {
  final service = TransaksiService();
  
  // Test valid transition
  await expectLater(
    service.updateStatusTransaksi('id', 'selesai', isDelivery: false),
    completes,
  );
  
  // Test invalid transition
  await expectLater(
    service.updateStatusTransaksi('id', 'diterima', isDelivery: false),
    throwsException,
  );
});
```

---

## 🎯 Next Steps (Opsional)

### 1. **Update UI untuk Menggunakan Helper Methods**
```dart
// Di kasir_dashboard.dart, ganti hardcoded switch dengan:
final nextStates = _transaksiService.getAvailableNextStates(
  transaksi.status,
  transaksi.isDelivery,
);
```

### 2. **Event-Driven Approach (Advanced)**
```dart
// Menggunakan events instead of direct state
final fsm = TransactionFSM(...);
fsm.processEvent(TransactionEvent.selesaikan);
```

### 3. **FSM with Actions (Advanced)**
```dart
// Menggunakan FSM dengan callbacks
final fsmWithActions = TransactionFSMWithActions(
  initialState: ...,
  isDelivery: ...,
  actions: MyTransactionActions(),
);
```

---

## 📚 Referensi

- **FSM Implementation**: `lib/core/transaction_fsm.dart`
- **TransactionService**: `lib/services/transaksi_service.dart`
- **Perbandingan Jalur**: `PERBANDINGAN_JALUR_TRANSAKSI.md`
- **Perbandingan State Management**: `PERBANDINGAN_STATE_MANAGEMENT.md`

---

## ✅ Summary

1. ✅ FSM sudah terintegrasi ke `TransaksiService`
2. ✅ Validasi Map-based sudah diganti dengan FSM
3. ✅ Helper methods sudah ditambahkan
4. ✅ Backward compatible - tidak ada breaking changes
5. ✅ Jalur transaksi tetap sama
6. ✅ Kode lebih formal dan maintainable

**Status: ✅ Ready to Use!**
