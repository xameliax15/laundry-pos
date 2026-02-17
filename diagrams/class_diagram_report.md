# Class Diagram - Laundry POS System
## Untuk Laporan Kerja Praktik Bab 4

Berikut adalah class diagram yang dibagi menjadi beberapa bagian agar lebih mudah dibaca:

---

## 1. Class Diagram - Model Data (Entity)

```mermaid
classDiagram
    class User {
        +String id
        +String username
        +String email
        +String role
        +String phone
    }

    class Customer {
        +String id
        +String name
        +String phone
        +String alamat
        +String kelurahan
        +String kecamatan
        +String kota
        +String kodePos
    }

    class Transaksi {
        +String id
        +String customerId
        +String customerName
        +String customerPhone
        +DateTime tanggalMasuk
        +DateTime tanggalSelesai
        +String status
        +double totalHarga
        +String catatan
        +bool isDelivery
    }

    class DetailLaundry {
        +String id
        +String idTransaksi
        +String jenisLayanan
        +String jenisBarang
        +int jumlah
        +double berat
        +String catatan
    }

    class Pembayaran {
        +String id
        +String transaksiId
        +double jumlah
        +DateTime tanggalBayar
        +String metodePembayaran
        +String status
        +String buktiPembayaran
        +String qrisId
        +String qrisString
        +String qrisUrl
        +DateTime qrisExpiredAt
        +String paymentGateway
        +isQrisPayment() bool
        +isQrisExpired() bool
    }

    class OrderKurir {
        +String id
        +String transaksiId
        +String kurirId
        +String alamatPengiriman
        +bool isCOD
        +String status
    }

    class StatusLog {
        +String id
        +String transaksiId
        +String oldStatus
        +String newStatus
        +String changedBy
        +String changedByName
        +DateTime changedAt
        +String notes
    }

    Transaksi "1" *-- "0..*" DetailLaundry : contains
    Transaksi "1" *-- "0..*" Pembayaran : has
    Transaksi "1" *-- "0..*" StatusLog : hasLogs
    Transaksi "0..*" o-- "1" Customer : belongsTo
    Transaksi "1" o-- "0..1" OrderKurir : hasDelivery
    OrderKurir "0..*" o-- "1" User : assignedTo
    StatusLog "0..*" o-- "1" User : changedBy
```

---

## 2. Class Diagram - Finite State Machine (FSM)

```mermaid
classDiagram
    class TransactionState {
        <<enumeration>>
        PENDING
        PROSES
        SELESAI
        DIKIRIM
        DITERIMA
    }

    class TransactionEvent {
        <<enumeration>>
        MULAI_PROSES
        SELESAIKAN
        KIRIM
        TERIMA
        AMBIL
    }

    class TransactionFSM {
        -TransactionState currentState
        -bool isDelivery
        +getCurrentState() TransactionState
        +getAvailableEvents() List
        +processEvent(event) bool
        +canTransitionTo(state) bool
        +isFinalState() bool
    }

    TransactionFSM "1" *-- "1" TransactionState : currentState
    TransactionFSM ..> TransactionEvent : uses
```

---

## 3. Class Diagram - Service Layer

```mermaid
classDiagram
    class TransaksiService {
        +getAllTransaksi() List~Transaksi~
        +getTransaksiById(id) Transaksi
        +getTransaksiByStatus(status) List~Transaksi~
        +createTransaksi(transaksi) void
        +updateTransaksi(transaksi) void
        +updateStatusTransaksi(id, status) void
        +searchTransaksi(query) List~Transaksi~
        +getDetailLaundry(id) List~DetailLaundry~
        +getPembayaran(id) List~Pembayaran~
        +createPembayaran(pembayaran) void
    }

    class CustomerService {
        +getAllCustomers() List~Customer~
        +getCustomerById(id) Customer
        +createCustomer(customer) void
        +updateCustomer(customer) void
        +searchCustomers(query) List~Customer~
    }

    class AuthService {
        +login(email, password) User
        +logout() void
        +getCurrentUser() User
        +isLoggedIn() bool
    }

    class QrisService {
        +generateQris(transaksiId, amount) QrisPayment
        +checkPaymentStatus(id) String
        +saveQrisPayment(data) Pembayaran
    }

    class StatusLogService {
        +logStatusChange(transaksiId, oldStatus, newStatus) void
        +getStatusHistory(transaksiId) List~StatusLog~
        +getRecentChanges(limit) List~StatusLog~
    }

    class NotificationService {
        +getRecentNotifications() List~NotificationItem~
        +showNotificationsDialog(context) void
    }

    class PrintService {
        +printReceipt(context, transaksi) void
        +previewReceipt(context, transaksi) void
        +showPrintDialog(context, transaksi) void
    }

    TransaksiService ..> Transaksi : manages
    TransaksiService ..> Pembayaran : manages
    TransaksiService ..> DetailLaundry : manages
    TransaksiService ..> TransactionFSM : uses
    TransaksiService ..> StatusLogService : uses
    CustomerService ..> Customer : manages
    AuthService ..> User : manages
    QrisService ..> Pembayaran : creates
    StatusLogService ..> StatusLog : manages
    NotificationService ..> Transaksi : reads
    PrintService ..> Transaksi : reads
```

---

## 4. Class Diagram Lengkap (Simplified)

```mermaid
classDiagram
    %% Models
    class User {
        +id: String
        +username: String
        +role: String
    }
    
    class Customer {
        +id: String
        +name: String
        +phone: String
        +alamat: String
    }
    
    class Transaksi {
        +id: String
        +customerId: String
        +status: String
        +totalHarga: double
        +isDelivery: bool
    }
    
    class DetailLaundry {
        +id: String
        +idTransaksi: String
        +jenisLayanan: String
        +jumlah: int
    }
    
    class Pembayaran {
        +id: String
        +transaksiId: String
        +jumlah: double
        +metodePembayaran: String
        +status: String
        +qrisId: String
    }
    
    class OrderKurir {
        +id: String
        +transaksiId: String
        +kurirId: String
        +isCOD: bool
    }

    class StatusLog {
        +id: String
        +transaksiId: String
        +oldStatus: String
        +newStatus: String
        +changedBy: String
    }

    %% FSM
    class TransactionFSM {
        +currentState: String
        +processEvent(): bool
    }

    %% Services
    class TransaksiService {
        +CRUD Operations
        +Status Management
    }
    
    class AuthService {
        +login()
        +logout()
    }

    class QrisService {
        +generateQris()
        +checkStatus()
    }

    class StatusLogService {
        +logStatusChange()
        +getHistory()
    }

    class PrintService {
        +printReceipt()
        +preview()
    }

    %% Relationships
    Transaksi "1" -- "*" DetailLaundry
    Transaksi "1" -- "*" Pembayaran
    Transaksi "1" -- "*" StatusLog
    Transaksi "*" -- "1" Customer
    Transaksi "1" -- "0..1" OrderKurir
    OrderKurir "*" -- "1" User
    TransaksiService --> Transaksi
    TransaksiService --> TransactionFSM
    TransaksiService --> StatusLogService
    AuthService --> User
    QrisService --> Pembayaran
    PrintService --> Transaksi
```

---

## Penjelasan Kelas Utama

### Model (Data Layer)
| Kelas | Deskripsi |
|-------|-----------|
| **User** | Data pengguna sistem (Owner, Kasir, Kurir) |
| **Customer** | Data pelanggan laundry |
| **Transaksi** | Data transaksi utama |
| **DetailLaundry** | Detail item dalam transaksi |
| **Pembayaran** | Data pembayaran transaksi (termasuk QRIS) |
| **OrderKurir** | Data penugasan kurir untuk delivery |
| **StatusLog** | Log perubahan status transaksi |

### Finite State Machine
| Kelas | Deskripsi |
|-------|-----------|
| **TransactionState** | Status transaksi (pending, proses, selesai, dikirim, diterima) |
| **TransactionEvent** | Event pemicu transisi status |
| **TransactionFSM** | Mesin pengelola status transaksi |

### Service Layer
| Kelas | Deskripsi |
|-------|-----------|
| **TransaksiService** | Logika bisnis untuk transaksi |
| **CustomerService** | Manajemen data pelanggan |
| **AuthService** | Autentikasi pengguna |
| **QrisService** | Integrasi pembayaran QRIS via Midtrans |
| **StatusLogService** | Logging perubahan status transaksi |
| **NotificationService** | Pengelolaan notifikasi aplikasi |
| **PrintService** | Pencetakan struk/receipt |

---

## Diagram Transisi Status (FSM)

```
┌─────────┐   mulai    ┌─────────┐  selesai   ┌─────────┐
│ PENDING │ ─────────▶ │ PROSES  │ ─────────▶ │ SELESAI │
└─────────┘            └─────────┘            └────┬────┘
                                                   │
                          ┌────────────────────────┴────────────────────────┐
                          │                                                 │
                          ▼ (Delivery)                                      ▼ (Pickup)
                    ┌─────────┐                                       ╔═════════╗
                    │ DIKIRIM │ ──────────────────────────────────▶   ║DITERIMA ║
                    └─────────┘           terima                      ╚═════════╝
```

---

## Metode Pembayaran

Aplikasi mendukung beberapa metode pembayaran:

| Metode | Deskripsi |
|--------|-----------|
| **Cash** | Pembayaran tunai di tempat |
| **Transfer** | Pembayaran via transfer bank |
| **QRIS** | Pembayaran digital via QR code (Midtrans) |
| **COD** | Cash on Delivery (bayar saat diantar kurir) |

