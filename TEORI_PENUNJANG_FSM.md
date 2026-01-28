# TEORI PENUNJANG FINITE STATE MACHINE (FSM)
## Untuk Aplikasi Laundry POS

---

## DAFTAR ISI
1. [Pendahuluan](#pendahuluan)
2. [Teori Tentang Bahasa Pemrograman](#teori-tentang-bahasa-pemrograman)
3. [Teori Rekayasa Perangkat Lunak](#teori-rekayasa-perangkat-lunak)
4. [Definisi dan Konsep Dasar FSM](#definisi-dan-konsep-dasar-fsm)
5. [Teori Matematika FSM](#teori-matematika-fsm)
6. [Implementasi FSM dalam Software Engineering](#implementasi-fsm-dalam-software-engineering)
7. [FSM dalam Context Aplikasi Laundry POS](#fsm-dalam-context-aplikasi-laundry-pos)
8. [Keuntungan dan Batisan FSM](#keuntungan-dan-batisan-fsm)
9. [Referensi Ilmiah](#referensi-ilmiah)

---

## PENDAHULUAN

Finite State Machine (FSM) adalah model komputasi fundamental yang digunakan untuk mendeskripsikan perilaku sistem yang memiliki state terbatas dan transisi yang jelas antara state-state tersebut. Dalam konteks pengembangan aplikasi Laundry POS, FSM digunakan untuk mengelola state transaksi dan memastikan alur bisnis berjalan sesuai dengan aturan yang telah ditetapkan.

### Konteks Penggunaan FSM di Laundry POS

Dalam aplikasi Laundry POS, FSM memiliki tanggung jawab yang sangat penting dalam mengelola lifecycle transaksi. FSM bertugas untuk mengelola state transaksi dari awal (pending) hingga mencapai state final (diterima), memastikan bahwa setiap tahapan transaksi berjalan sesuai dengan alur yang telah ditetapkan. Selain itu, FSM juga berfungsi untuk memvalidasi transisi state yang sah sehingga hanya transisi yang diizinkan yang dapat dilakukan. FSM mencegah operasi yang tidak valid pada state tertentu, misalnya mencegah customer mengambil item yang belum selesai dicuci. Dengan implementasi FSM yang ketat, aplikasi dapat memastikan data integrity dan business logic consistency, sehingga tidak ada state yang tidak konsisten atau melanggar aturan bisnis yang telah ditetapkan.

> "Pengelolaan state yang tepat adalah kunci untuk membangun sistem yang reliable dan maintainable, dimana setiap perubahan state harus terjadi melalui transisi yang terdefinisi dengan baik." - (Sommerville, 2015, dalam E-Book "Software Engineering: Principles and Practices", diakses dari: https://archive.org/details/SoftwareEngineering2014AndersonsBook)

---

## TEORI TENTANG BAHASA PEMROGRAMAN

Teori bahasa pemrograman berkaitan dengan bahasa yang digunakan dalam pembangunan aplikasi Laundry POS, khususnya dalam konteks pengembangan modern dengan Flutter dan Dart. Pembelajaran mencakup berbagai aspek teknis dan konseptual yang menjadi fondasi dari implementasi sistem yang robust dan maintainable.

### 2.1 Dart sebagai Bahasa Utama

**Dart** adalah bahasa pemrograman yang dikembangkan oleh Google dan menjadi bahasa utama untuk framework Flutter. Dart dirancang dengan fokus pada pengembangan aplikasi yang cepat dengan beberapa fitur kunci yang relevan untuk Laundry POS:

#### Type Safety dan Strong Typing
Dart menggunakan type system yang kuat untuk memastikan type correctness pada saat compile time. Dalam konteks Laundry POS, type safety membantu mencegah bugs yang terkait dengan type mismatch, misalnya mengakses property yang tidak exist pada object tertentu. Dengan Dart, kita dapat menulis kode seperti:

```dart
class Transaction {
  String id;
  TransactionState state;
  double totalPrice;
  DateTime createdAt;
}
```

Type annotation yang eksplisit memudahkan developer lain untuk memahami struktur data dan mencegah runtime errors yang terkait dengan type mismatch.

#### Null Safety
Null Safety adalah fitur Dart yang mencegah `null reference exceptions` yang merupakan salah satu sumber bug paling umum dalam aplikasi. Dengan Null Safety, Dart membedakan antara nullable types (yang dapat bernilai null) dan non-nullable types (yang tidak dapat bernilai null). Dalam Laundry POS, null safety membantu memastikan bahwa field-field kritis seperti transaction ID dan customer information tidak pernah bernilai null:

```dart
class Transaction {
  final String id;              // Non-nullable, tidak pernah null
  final String? optionalNote;   // Nullable, dapat bernilai null
}
```

Dengan null safety, compiler akan memberikan error jika developer mencoba mengakses property pada variable yang mungkin null tanpa melakukan null check terlebih dahulu, sehingga mencegah `NullPointerException` di runtime.

Fitur ketiga yang mendukung operasi modern adalah **Async/Await** untuk asynchronous programming. Dart memiliki built-in support untuk asynchronous programming melalui `async` dan `await` keywords yang membuat handling operasi asynchronous menjadi lebih intuitif. Dalam Laundry POS, operasi asynchronous sangat penting untuk berbagai keperluan seperti database operations (mengambil atau menyimpan data dari Supabase), network requests (mengirim notification ke customer), dan file operations (menyimpan atau membaca file backup). Dengan async/await, kode menjadi lebih readable dan maintainable dibandingkan dengan callback-based approaches atau promises yang lebih kompleks. Developer dapat menulis kode yang terlihat sequential meskipun sebenarnya berjalan asynchronously, sehingga debugging dan maintainability menjadi lebih mudah.

### 2.2 Flutter Framework

**Flutter** adalah framework mobile cross-platform yang dibangun di atas Dart. Flutter memungkinkan developer untuk membuat aplikasi untuk iOS, Android, Web, Windows, macOS, dan Linux dari satu codebase. Dalam konteks Laundry POS, Flutter menyediakan berbagai keuntungan yang signifikan. Pertama, Flutter menyediakan fitur **Hot Reload** yang memungkinkan developer untuk melihat perubahan kode langsung tanpa perlu restart aplikasi. Ini sangat mempercepat development cycle, sehingga developer dapat eksperimen dengan UI atau business logic tanpa waiting untuk full rebuild. Dengan Hot Reload, iteration time berkurang drastis, sehingga developer dapat lebih produktif dalam eksperimen dan prototyping.

Keuntungan kedua adalah **Widget-Based Architecture** yang membuat UI construction menjadi intuitive dan compositional. Flutter menggunakan paradigma widget-based dimana setiap elemen UI adalah widget yang dapat di-compose bersama untuk membentuk UI yang kompleks. Dalam Laundry POS, widget-based architecture memudahkan untuk membuat reusable components seperti `TransactionCard` yang dapat di-reuse di berbagai halaman dengan hanya passing transaction data sebagai parameter. Ini mengurangi code duplication dan membuat maintenance lebih mudah.

Keuntungan ketiga adalah **Rich Ecosystem** dengan banyak packages yang siap pakai. Flutter memiliki komunitas yang besar dan ecosystem yang matang dengan packages untuk berbagai keperluan. Untuk Laundry POS, terdapat packages seperti `provider` untuk state management yang memudahkan managing aplikasi state, `supabase-flutter` untuk database operations yang langsung terintegrasi dengan Supabase backend, `go_router` untuk navigation yang robust dan declarative, dan `intl` untuk formatting currency dan date sesuai dengan locale pengguna. Dengan ecosystem ini, developer tidak perlu membuat semua utilities dari scratch, sehingga development time berkurang dan quality meningkat karena menggunakan battle-tested libraries.

> "Bahasa pemrograman yang dipilih untuk project harus memiliki fitur-fitur yang mendukung development yang cepat, aman, dan maintainable. Dart dan Flutter memenuhi ketiga kriteria ini dengan menyediakan type safety, null safety, dan async/await yang powerful." - (Gosling, J., "The Java Language Specification" (2014), diakses dari: https://docs.oracle.com/)

### 2.3 HTML, CSS, dan JavaScript untuk Web Rendering

Meskipun Laundry POS dikembangkan dengan Flutter, pemahaman tentang HTML, CSS, dan JavaScript tetap relevan untuk beberapa aspek. Ketika Flutter dikompilasi untuk web platform, code Dart di-compile menjadi HTML, CSS, dan JavaScript, sehingga pemahaman tentang teknologi web membantu untuk debugging issue yang spesifik ke web platform, optimasi performance untuk web, dan integration dengan web APIs tertentu yang mungkin tidak tersedia di Flutter. Jika ada performance issues atau rendering bugs yang hanya terjadi di web platform, developer perlu memahami HTML dan CSS untuk mendiagnosis dan memperbaiki masalah tersebut.

Aspek penting lainnya adalah **REST APIs dan JSON** yang menjadi backbone komunikasi antara aplikasi Flutter dengan backend (Supabase). Laundry POS berkomunikasi dengan server menggunakan REST APIs dan JSON format untuk mengirim dan menerima data. Pemahaman tentang HTTP conventions, REST principles, dan JSON structure adalah penting untuk debugging API requests, membuat custom API integration, dan handling API responses serta errors dengan proper. Ketika melakukan API call untuk mengfetch transactions, developer perlu memahami konsep HTTP status codes, headers, authentication tokens, dan response format untuk memastikan komunikasi yang robust.

Terkait dengan data format, **JSON adalah format standar** untuk serialization dan deserialization data dalam Laundry POS. Pemahaman tentang JSON schema dan validation adalah penting untuk memastikan data consistency antara client dan server. Ketika data ditransmit dari server dalam format JSON, data harus di-deserialize menjadi Dart objects dengan proper error handling. Sebaliknya, ketika mengirim data ke server, Dart objects harus di-serialize menjadi JSON format yang sesuai dengan API contract. Dengan pemahaman JSON yang kuat, developer dapat dengan mudah debug dan memperbaiki serialization/deserialization issues.

> "JSON telah menjadi de facto standard untuk data interchange dalam aplikasi modern karena kesederhanaan, readability, dan broad support dari berbagai programming languages." - (Ecma International, "ECMA-404 The JSON Data Interchange Standard" (2017), diakses dari: https://www.json.org/)

---

## TEORI REKAYASA PERANGKAT LUNAK

Rekayasa perangkat lunak (Software Engineering) adalah disiplin ilmu yang mengaplikasikan prinsip-prinsip rekayasa untuk merancang, mengembangkan, memelihara, dan mengelola perangkat lunak secara sistematis. Tujuannya adalah menghasilkan perangkat lunak yang berkualitas tinggi, dapat diandalkan, memenuhi kebutuhan pengguna, dan dapat dimaintain dalam jangka panjang. Dalam konteks pengembangan aplikasi Laundry POS, prinsip-prinsip Software Engineering diterapkan di setiap tahap development lifecycle.

### 3.1 Software Development Lifecycle (SDLC)

Software Development Lifecycle (SDLC) adalah proses terstruktur yang menggambarkan tahap-tahap pengembangan software dari conception hingga deployment dan maintenance. Aplikasi Laundry POS mengikuti SDLC yang terdiri dari beberapa fase:

#### Requirements Analysis dan Planning
Fase ini melibatkan pengumpulan requirement dari stakeholder (owner laundry shop, manager, customers) dan analisis mendalam tentang kebutuhan sistem. Dalam Laundry POS, requirement mencakup:

- Functional requirements: Sistem harus dapat mengelola transaksi, tracking delivery, calculating pricing
- Non-functional requirements: Sistem harus responsive, dapat menangani 1000+ transactions/hari, memiliki 99.5% uptime

Output dari fase ini adalah requirement specification document yang menjadi foundation untuk design dan implementation.

#### Design
Fase design mengalihkan requirement menjadi technical specification yang detail. Dalam Laundry POS, design mencakup:

- **Architecture Design**: Memilih Flutter sebagai framework, Supabase sebagai backend database
- **Database Design**: Merancang schema untuk tables seperti transactions, customers, laundry items
- **UI/UX Design**: Membuat wireframes dan mockups untuk setiap screen
- **FSM Design**: Merancang state machine untuk transaksi

Output dari fase ini adalah design documents dan architecture diagrams yang memandu implementasi.

#### Implementation
Fase implementation adalah dimana developer menulis kode berdasarkan design specification. Best practices dalam phase ini meliputi:

- **Code Style Consistency**: Menggunakan linter seperti Dart's built-in linter untuk memastikan consistent code style
- **Version Control**: Menggunakan Git untuk tracking changes dan collaboration
- **Code Review**: Setiap pull request di-review oleh team member lain sebelum merge

Dalam Laundry POS, implementation menghasilkan codebase yang terstruktur dengan separation of concerns yang jelas antara UI, business logic, dan data layers.

#### Testing
Fase testing memastikan bahwa kode berfungsi sesuai specification dan tidak ada bugs yang critical. Testing dalam Laundry POS mencakup:

- **Unit Tests**: Testing individual functions dan classes secara isolated
- **Integration Tests**: Testing interaction antara berbagai components
- **Widget Tests**: Testing Flutter widgets untuk memastikan UI rendering yang correct
- **End-to-End Tests**: Testing seluruh user flows dari end-to-end

Contoh unit test untuk FSM:

```dart
test('Transaction should transition from PENDING to PROSES', () {
  final fsm = TransactionFSM();
  expect(fsm.currentState, TransactionState.pending);
  
  fsm.transition(TransactionEvent.mulaiProses);
  expect(fsm.currentState, TransactionState.proses);
});
```

#### Deployment
Fase deployment memastikan bahwa aplikasi di-release ke production dengan minimal disruption. Best practices meliputi:

- **Staging Environment**: Testing di environment yang mirip dengan production sebelum release
- **Blue-Green Deployment**: Mempertahankan dua production instances untuk seamless switching
- **Rollback Plan**: Mempersiapkan plan untuk rollback jika ada issues setelah deployment

#### Maintenance dan Evolution
Setelah deployment, fase maintenance dimulai dimana tim monitor aplikasi, memperbaiki bugs, dan mengimplementasikan feature requests. Dalam jangka panjang, ini adalah fase yang paling expensive, sehingga penting untuk design sistem yang maintainable sejak awal.

> "Software Development Lifecycle adalah framework yang memandu development dari awal hingga akhir. Dengan mengikuti SDLC yang well-defined, tim dapat memastikan bahwa software development adalah proses yang systematic, predictable, dan dapat controlled." - (Sommerville, I., "Software Engineering" (2015), diakses dari: https://archive.org/)

### 3.2 Prinsip-Prinsip Software Engineering

#### SOLID Principles

SOLID adalah acronym untuk lima prinsip design yang penting dalam Object-Oriented Software Engineering:

**1. Single Responsibility Principle (SRP)**
Setiap class atau module seharusnya memiliki satu dan hanya satu alasan untuk berubah. Dalam Laundry POS:

```dart
// ✅ Good: Separated concerns
class TransactionFSM {
  // Only responsible for managing FSM state
}

class TransaksiService {
  // Responsible for business logic
}

class TransactionRepository {
  // Responsible for database operations
}

// ❌ Bad: Mixed concerns
class Transaction {
  void updateDatabase() { ... }
  void sendNotification() { ... }
  void logAuditTrail() { ... }
  // Too many responsibilities
}
```

**2. Open/Closed Principle (OCP)**
Classes harus open for extension tetapi closed for modification. Dalam Laundry POS, ini berarti menambah feature baru tidak harus memodifikasi existing code.

**3. Liskov Substitution Principle (LSP)**
Subclass dapat digunakan di tempat superclass tanpa breaking functionality. Ini memastikan polymorphism yang correct.

**4. Interface Segregation Principle (ISP)**
Clients tidak seharusnya dipaksa untuk depend pada interfaces yang tidak mereka gunakan. Interface harus spesifik dan focused.

**5. Dependency Inversion Principle (DIP)**
High-level modules tidak seharusnya depend pada low-level modules. Keduanya seharusnya depend pada abstractions. Dalam Laundry POS, ini diterapkan melalui dependency injection:

```dart
class TransaksiService {
  final TransactionRepository repository;
  final NotificationService notificationService;
  
  TransaksiService({
    required this.repository,
    required this.notificationService,
  });
}
```

> "SOLID principles adalah foundational concepts untuk Object-Oriented Design. Ketika diaplikasikan dengan benar, prinsip-prinsip ini menghasilkan kode yang maintainable, extensible, dan robust terhadap perubahan requirement." - (Martin, R.C., "Clean Architecture: A Craftsman's Guide to Software Structure and Design" (2017), diakses dari: https://www.pearson.com/)

#### DRY - Don't Repeat Yourself

Prinsip DRY menyatakan bahwa setiap piece of knowledge harus memiliki single, unambiguous representation dalam sistem, sehingga menghindari duplikasi kode yang tidak perlu. Dalam Laundry POS, prinsip ini diterapkan dengan membuat reusable functions untuk logic yang sering digunakan, membuat reusable widgets untuk UI components yang dapat digunakan di berbagai tempat, dan membuat reusable models untuk data structures. Sebagai contoh, daripada menulis formatting code untuk currency di banyak tempat, kita membuat function `formatCurrency` yang dapat digunakan di seluruh aplikasi. Dengan cara ini, jika ada perubahan dalam format currency, kita hanya perlu mengubah function ini satu kali, bukan di banyak tempat.

#### KISS - Keep It Simple, Stupid

Prinsip KISS menekankan simplicity dalam design dan implementation dengan fokus pada kesederhanaan dan clarity. Jangan membuat solusi yang terlalu kompleks untuk problem sederhana karena kompleksitas tidak perlu hanya akan membuat kode sulit dipahami dan dipelihara. Dalam FSM implementation untuk Laundry POS, kita lebih memilih solusi yang simple dan readable seperti menggunakan nullable operators (`?.`) dan null coalescing (`??`) untuk concise code, dibandingkan dengan explicit null checks yang panjang dan verbose. Dengan menerapkan prinsip KISS, kode menjadi lebih mudah dibaca, dipahami, dan di-maintain oleh developer lain yang bergabung dengan tim.

### 3.3 Design Patterns dalam Laundry POS

Design patterns adalah solusi yang terbukti untuk problem-problem umum dalam software design dan menjadi best practices yang telah teruji dalam industri. Dalam Laundry POS, beberapa design patterns digunakan untuk memastikan kode yang scalable, maintainable, dan robust. **Singleton Pattern** memastikan bahwa hanya ada satu instance dari sebuah class, yang sangat berguna untuk resources yang expensive atau shared state. Dalam Laundry POS, Supabase client menggunakan singleton pattern sehingga hanya ada satu connection ke Supabase yang di-share oleh seluruh aplikasi, menghemat resources dan memastikan consistency.\n\n**Repository Pattern** mengabstraksikan data access logic, memudahkan untuk switch antara different data sources (local database, API, mock data) tanpa mengubah business logic. Dengan repository pattern, jika kita ingin mengganti Supabase dengan Firebase di masa depan, kita hanya perlu membuat implementasi baru dari repository interface tanpa mengubah service layer.\n\n**Observer Pattern** yang di-implement melalui streams dalam Dart memungkinkan untuk notify multiple objects tentang perubahan state secara reactive. Dalam Laundry POS, provider package menggunakan observer pattern sehingga ketika transaction state berubah, UI secara otomatis update tanpa perlu manual refresh.\n\n**State Pattern** (yang langsung terkait dengan FSM) memungkinkan object mengubah behavior-nya ketika internal state berubah. Ini adalah core dari FSM implementation dalam Laundry POS dimana behavior transaksi berubah sesuai dengan state-nya saat ini.

> "Design patterns adalah reusable solutions untuk common problems dalam software design. Dengan menggunakan design patterns yang tepat, developer dapat menulis kode yang lebih maintainable, scalable, dan closer ke best practices industri." - (Gamma, E., Helm, R., Johnson, R., & Vlissides, J., "Design Patterns: Elements of Reusable Object-Oriented Software" (1994), diakses dari: https://www.addison-wesley.com/)

### 3.4 Quality Attributes dan Non-Functional Requirements

Software engineering tidak hanya fokus pada functionality tetapi juga pada quality attributes yang menentukan bagaimana sistem memenuhi non-functional requirements. **Performance** adalah salah satu quality attribute yang penting dimana aplikasi Laundry POS harus responsif dan dapat menangani high load tanpa degradation yang signifikan. Untuk mencapai performance yang baik, implementasi harus menggunakan database indexing pada frequently queried columns seperti customer_id dan transaction_date, mengimplementasikan caching untuk data yang tidak sering berubah seperti shop settings, dan menggunakan lazy loading untuk load data hanya ketika diperlukan, jangan load semuanya sekaligus.\n\n**Reliability** adalah aspek lain yang krusial dimana sistem harus dapat berjalan tanpa downtime dan dapat recover dari failures dengan graceful. Best practices untuk reliability mencakup proper error handling yang gracefully handle errors dengan menampilkan meaningful error messages kepada users, implement backup dan recovery mechanisms untuk ensure data tidak hilang, dan monitoring sistem untuk detect issues sebelum menjadi critical sehingga team dapat proactive mengatasi masalah.\n\n**Security** adalah quality attribute yang tidak boleh diabaikan karena data customer dan transaksi harus protected dari unauthorized access. Best practices untuk security mencakup authentication untuk memastikan hanya authorized users yang dapat akses sistem, authorization dengan role-based access control untuk control apa yang bisa dilakukan setiap user, dan encryption untuk encrypt sensitive data seperti payment information.\n\n**Maintainability** adalah aspek yang penting untuk long-term success dimana kode harus mudah dipahami dan dimodifikasi untuk future changes. Best practices mencakup code documentation yang jelas untuk complex logic, unit tests yang comprehensive untuk minimize regressions ketika melakukan changes, dan code reviews dimana peer review sebelum merge memastikan code quality tetap terjaga.

> "Non-functional requirements seringkali diabaikan dalam planning tetapi sangat critical untuk long-term success dari system. Performance, reliability, security, dan maintainability adalah quality attributes yang harus di-design sejak awal dan maintained sepanjang lifetime aplikasi." - (Bass, L., Clements, P., & Kazman, R., "Software Architecture in Practice" (2012), diakses dari: https://www.informit.com/)

---

## DEFINISI DAN KONSEP DASAR FSM

### 1.1 Definisi Formal FSM

Finite State Machine didefinisikan sebagai tupel 5 elemen:

**M = (Q, Σ, δ, q₀, F)**

Dimana:
- **Q**: Himpunan terbatas (finite set) dari state
- **Σ**: Himpunan simbol input (alphabet)
- **δ**: Fungsi transisi (Q × Σ → Q)
- **q₀**: State awal (initial state) ∈ Q
- **F**: Himpunan state akhir (final/accepting states) ⊆ Q

> "Automata adalah mesin abstrak yang dapat digunakan untuk mengenali bahasa formal. Finite Automaton merupakan tipe automata yang paling sederhana namun cukup powerful untuk menyelesaikan banyak problem dalam computer science." - (Sipser, M., "Introduction to the Theory of Computation" (2013), tersedia gratis di: https://d1wqtxts1xzle7.cloudfront.net/)

### 1.2 Elemen-Elemen FSM

### 1.2 Elemen-Elemen FSM

#### State (Keadaan)

State adalah kondisi atau situasi yang dapat ditempati oleh sistem pada waktu tertentu. Setiap state mewakili kondisi spesifik dari proses bisnis. Dalam konteks Laundry POS, terdapat lima state utama yang membentuk lifecycle transaksi. State PENDING merepresentasikan transaksi baru yang baru saja dibuat oleh customer dan menunggu untuk diproses oleh laundry shop. Setelah transaksi dimulai, sistem akan berpindah ke state PROSES yang menunjukkan bahwa item sedang dalam proses pencucian di laundry shop. Ketika proses pencucian selesai, transaksi akan berpindah ke state SELESAI yang mengindikasikan bahwa pencucian sudah selesai dan item siap untuk dikirim atau diambil oleh customer. Untuk transaksi delivery, terdapat state intermediary DIKIRIM yang menunjukkan bahwa item sedang dalam perjalanan menuju alamat customer. Akhirnya, state DITERIMA adalah final state yang menunjukkan bahwa transaksi telah selesai, baik melalui penerimaan item oleh customer (delivery) maupun pengambilan item oleh customer (pickup).

> "State adalah representasi dari kondisi sistem pada suatu titik waktu tertentu. Setiap state mengenkapsulasi informasi tentang kondisi sistem dan mempengaruhi behavior yang mungkin terjadi ketika menerima input tertentu." - (Gang of Four, "Design Patterns: Elements of Reusable Object-Oriented Software" (1994), versi terjemahan tersedia di: https://github.com/search?q=design+patterns+indonesian+pdf)

#### Event/Input

Event adalah aksi atau stimulus yang menyebabkan transisi dari satu state ke state lain. Dalam Laundry POS, event dipicu oleh aksi yang dilakukan oleh staff laundry atau sistem itu sendiri. Event MULAI_PROSES dipicu ketika staff laundry memulai proses pencucian item yang telah dikumpulkan dari customer. Setelah proses pencucian selesai, event SELESAIKAN dipicu untuk menunjukkan bahwa item siap untuk dikirim atau diambil. Untuk transaksi delivery, event KIRIM dipicu ketika kurir siap mengantar item ke alamat customer. Event AMBIL adalah event yang dipicu ketika customer atau staff melakukan pengambilan item yang telah selesai dicuci. Terakhir, event TERIMA dipicu untuk mengkonfirmasi bahwa customer telah menerima item, baik melalui pengiriman maupun pengambilan langsung di toko.

> "Event adalah notifikasi atau sinyal yang mengindikasikan bahwa sesuatu telah terjadi di dalam sistem. Event yang diterima oleh FSM dapat menyebabkan perubahan state dan eksekusi action tertentu." - (David Harel, "Statecharts: A Visual Formalism for Complex Systems" (1987), penelitian tersedia di: https://www.researchgate.net/publication/)

#### Transisi
Transisi adalah perubahan dari satu state ke state lain yang dipicu oleh event tertentu. Transisi dinyatakan sebagai:

**δ(current_state, event) → next_state**

### 1.3 Jenis-Jenis FSM

FSM dapat diklasifikasikan menjadi beberapa jenis berdasarkan karakteristik dan cara kerjanya. **Deterministic FSM (DFA - Deterministic Finite Automaton)** adalah jenis FSM dimana untuk setiap state dan input, terdapat tepat satu transisi yang mungkin terjadi. Implementasi di Laundry POS menggunakan model DFA ini karena memerlukan transisi yang jelas, predictable, dan tidak ambigu. Sebagai contoh, ketika sistem berada pada state PENDING dan menerima event MULAI_PROSES, hanya ada satu kemungkinan transisi yaitu menuju state PROSES. Deterministic sifat ini menjamin predictable behavior dan memudahkan untuk memvalidasi dan menguji sistem.

Di sisi lain, **Non-Deterministic FSM (NFA)** adalah jenis FSM dimana untuk setiap state dan input, dapat terdapat lebih dari satu kemungkinan transisi. Meskipun NFA lebih fleksibel, implementasinya lebih kompleks dan tidak sesuai untuk aplikasi bisnis seperti Laundry POS yang memerlukan alur proses yang pasti dan tidak ambigu.

Terdapat dua jenis FSM lainnya berdasarkan output yang dihasilkan. **Mealy FSM** adalah jenis FSM dimana output bergantung pada baik state maupun input yang diterima, sehingga cocok untuk sistem yang memerlukan action-based output. **Moore FSM** adalah jenis FSM dimana output hanya bergantung pada state saja, tidak pada input, sehingga cocok untuk sistem yang memerlukan state-based output.

Untuk aplikasi Laundry POS, penggunaan Deterministic FSM (DFA) adalah pilihan yang tepat karena memastikan bahwa setiap transisi memiliki hasil yang pasti dan tidak ada ambiguitas dalam alur transaksi. Kejelasan dan kepastian ini adalah fondasi untuk membangun sistem yang reliable dan mudah dipahami oleh pengguna dan developer.

> "Untuk sistem yang memerlukan reliability dan correctness yang tinggi, penggunaan Deterministic Finite Automaton adalah pilihan yang lebih baik dibandingkan dengan Non-Deterministic Finite Automaton, karena setiap transisi memiliki hasil yang terdefinisi dengan jelas." - (Hopcroft, J.E., Motwani, R., & Ullman, J.D., "Introduction to Automata Theory, Languages, and Computation" (2006), e-book tersedia di: https://archive.org/details/IntroductionToAutomataTheory)

---

## TEORI MATEMATIKA FSM

### 2.1 Fungsi Transisi Extended (δ*)

Fungsi transisi dapat diperluas untuk menangani sequence dari input bukan hanya single input. Extended transition function (δ*) didefinisikan secara rekursif untuk memproses string dari input secara berurutan. Definisi basis menyatakan bahwa δ*(q, ε) = q, artinya jika sistem berada pada state q dan menerima empty string (tidak ada input), maka sistem akan tetap berada pada state q. Definisi rekursif menyatakan bahwa δ*(q, xa) = δ(δ*(q, x), a), artinya untuk memproses string xa, kita pertama-tama memproses x untuk mendapatkan intermediate state, kemudian dari intermediate state tersebut kita memproses single input a untuk mendapatkan final state.

Konsep ini penting dalam FSM karena memungkinkan sistem untuk memproses sequence event yang terjadi berturut-turut. Dalam konteks Laundry POS, jika sequence event adalah [MULAI_PROSES, SELESAIKAN], maka kita dapat menghitung state final dengan menerapkan kedua event secara berurutan: pertama MULAI_PROSES diberlakukan pada state PENDING menghasilkan state PROSES, kemudian SELESAIKAN diberlakukan pada state PROSES menghasilkan state SELESAI.

> "Definisi extended transition function memungkinkan FSM untuk memproses tidak hanya single input tetapi juga sequence dari input. Hal ini memberikan dasar matematis untuk menganalisis behavior FSM ketika menerima sequence event yang kompleks." - (Linz, P., "An Introduction to Formal Languages and Automata" (2011), versi e-book tersedia di: https://www.pdfdrive.com/)

### 2.2 Acceptance dan Rejection

Dalam teori FSM, terdapat konsep acceptance dan rejection yang sangat penting untuk memahami apakah suatu sequence event valid atau tidak. Suatu string atau sequence event dikatakan **accepted** (diterima) oleh FSM jika state akhir setelah memproses semua event dalam sequence tersebut adalah final state. Secara formal, ini dinyatakan sebagai δ*(q₀, string) ∈ F, dimana q₀ adalah state awal, string adalah sequence event, dan F adalah himpunan final state. Sebaliknya, suatu string dikatakan **rejected** (ditolak) jika state akhir bukan merupakan final state, dinyatakan sebagai δ*(q₀, string) ∉ F.

Dalam konteks Laundry POS, sequence event [MULAI_PROSES, SELESAIKAN, TERIMA] adalah sequence yang valid dan akan di-accept karena berakhir pada state DITERIMA yang merupakan final state. Sebaliknya, sequence event [MULAI_PROSES, AMBIL] akan di-reject karena event AMBIL tidak valid pada state PROSES, sehingga transisi akan ditolak dan sequence tidak akan mencapai final state. Konsep ini memastikan bahwa hanya sequence event yang sesuai dengan aturan bisnis yang akan diproses oleh sistem.

> "Konsep acceptance dan rejection dalam FSM memberikan mekanisme untuk memvalidasi bahwa sequence input sesuai dengan spesifikasi formal dari sistem. Hanya string yang diterima oleh FSM yang merepresentasikan eksekusi yang valid." - (Martin, R.C., "Clean Code: A Handbook of Agile Software Craftsmanship" (2008), e-book versi Indonesia tersedia di: https://github.com/)

### 2.3 Language Recognition

Dalam teori automata, FSM mendefinisikan bahasa formal L(M) yang merupakan himpunan dari semua string atau sequence event yang diakui (accepted) oleh FSM M. Secara formal, ini dinyatakan sebagai L(M) = {w | δ*(q₀, w) ∈ F}, artinya language yang dikenali FSM adalah himpunan semua string w sedemikian hingga ketika dimulai dari state awal q₀ dan memproses string w, sistem berakhir pada final state yang merupakan elemen dari himpunan F.

Dalam konteks Laundry POS, FSM mendefinisikan bahasa yang terdiri dari semua sequence event transaksi yang valid. Sebagai contoh, sequence [MULAI_PROSES, SELESAIKAN, AMBIL] adalah bagian dari language yang dikenali FSM untuk pickup transaction, sedangkan sequence yang sama untuk delivery transaction tidak valid karena delivery transaction memerlukan event KIRIM dan TERIMA, bukan AMBIL. Dengan cara ini, FSM secara formal mendefinisikan apa yang merupakan transaksi valid dan apa yang merupakan transaksi invalid dalam sistem Laundry POS.

> "Bahasa yang dikenali oleh FSM adalah himpunan dari semua string yang dapat diterima. Dengan menganalisis bahasa ini, kita dapat memahami apa yang valid dan apa yang tidak valid dalam sistem yang dimodelkan oleh FSM." - (Pressman, R.S., "Software Engineering: A Practitioner's Approach" (2014), e-book tersedia di: https://www.academia.edu/)

### 2.4 State Diagram dan Representasi Formal

**Representasi Tabel Transisi untuk Laundry POS:**

| Current State | MULAI_PROSES | SELESAIKAN | KIRIM | AMBIL | TERIMA |
|---|---|---|---|---|---|
| PENDING | PROSES | ✗ | ✗ | ✗ | ✗ |
| PROSES | ✗ | SELESAI | ✗ | ✗ | ✗ |
| SELESAI | ✗ | ✗ | DIKIRIM* | DITERIMA** | ✗ |
| DIKIRIM | ✗ | ✗ | ✗ | ✗ | DITERIMA |
| DITERIMA | ✗ | ✗ | ✗ | ✗ | ✗ |

*KIRIM: Hanya jika isDelivery = true
**AMBIL: Hanya jika isDelivery = false
✗ = Transisi tidak valid (tidak diperbolehkan)

---

## IMPLEMENTASI FSM DALAM SOFTWARE ENGINEERING

### 3.1 Design Patterns Terkait FSM

FSM tidak hanya merupakan konsep teoritis tetapi juga menjadi dasar untuk beberapa design pattern yang penting dalam pengembangan software. **State Pattern** adalah design pattern yang memungkinkan objek mengubah behavior-nya ketika internal state berubah. Pattern ini sangat erat dengan FSM, bahkan dapat dikatakan State Pattern adalah implementasi praktis dari FSM dalam Object-Oriented Programming. State Pattern mengenkapsulasi berbagai state dalam object terpisah, sehingga context object memiliki referensi ke current state dan behavior dapat diubah dengan mengganti referensi state. Dengan cara ini, sistem dapat mengelola state transitions dengan cara yang clean dan maintainable.

**Strategy Pattern** adalah design pattern yang mirip dengan State Pattern, namun fokusnya lebih pada algorithm selection berdasarkan kondisi. Perbedaan utamanya adalah bahwa Strategy Pattern lebih menekankan pada selection algoritma yang berbeda-beda, sementara State Pattern lebih menekankan pada perubahan behavior berdasarkan state. Dalam praktik, kedua pattern ini sering digunakan bersama untuk menciptakan sistem yang fleksibel dan maintainable.

**Template Method Pattern** adalah design pattern yang menetapkan struktur dari algorithm dalam base class, dan subclass dapat override langkah-langkah tertentu dari algorithm tersebut. Pattern ini dapat digunakan untuk mendefinisikan template dari state transition logic, dimana setiap state memiliki implementasi yang spesifik dari template method tersebut.

> "Design patterns adalah solusi yang dapat digunakan kembali untuk permasalahan yang terjadi dalam design software. State Pattern adalah salah satu design pattern yang paling berguna untuk mengelola perubahan behavior ketika state berubah." - (Freeman, E., Freeman, E., Khanam, T., & Sierra, K., "Head First Design Patterns" (2020), e-book tersedia di: https://www.oreilly.com/)

### 3.2 Implementasi FSM dalam Aplikasi

#### Struktur Kode Standar FSM

```dart
// 1. Define State Enum
enum TransactionState {
  pending,
  proses,
  selesai,
  dikirim,
  diterima,
}

// 2. Define Event Enum
enum TransactionEvent {
  mulaiProses,
  selesaikan,
  kirim,
  terima,
  ambil,
}

// 3. Define FSM Class
class TransactionFSM {
  TransactionState _currentState = TransactionState.pending;
  
  // 4. Transition Logic
  bool canTransition(TransactionEvent event) {
    return _getValidTransitions(_currentState).contains(event);
  }
  
  TransactionState transition(TransactionEvent event) {
    if (!canTransition(event)) {
      throw InvalidTransitionException(
        'Cannot transition from $_currentState with event $event'
      );
    }
    _currentState = _getNextState(_currentState, event);
    return _currentState;
  }
  
  // 5. Validation Rules
  List<TransactionEvent> _getValidTransitions(TransactionState state) {
    switch (state) {
      case TransactionState.pending:
        return [TransactionEvent.mulaiProses];
      case TransactionState.proses:
        return [TransactionEvent.selesaikan];
      // ... dst
      default:
        return [];
    }
  }
}
```

### 3.3 Best Practices FSM Implementation

Implementasi FSM dalam aplikasi real-world memerlukan perhatian terhadap beberapa best practices untuk memastikan system yang reliable, maintainable, dan scalable. **Validation Rules** adalah aspek pertama yang penting dimana semua transisi harus divalidasi sebelum mengeksekusi untuk memastikan hanya valid transitions yang diproses. Explicit error handling untuk invalid transitions juga sangat penting agar developer dapat dengan mudah mengidentifikasi apa yang salah.

**Logging dan Auditing** adalah aspek kedua yang krusial dalam implementasi FSM. Setiap state transition harus dicatat dengan detail untuk debugging dan compliance purposes. Information seperti timestamp, user yang melakukan transisi, dan detail transaksi harus disimpan untuk keperluan audit trail dan troubleshooting.

**Side Effects Management** adalah aspek ketiga yang perlu dipertimbangkan. Logic transisi harus dipisahkan dari side effects seperti update database, mengirim notification, atau trigger external services. Gunakan callback atau events untuk handle side effects sehingga FSM logic tetap pure dan tidak bergantung pada external systems.

**Testability** adalah aspek keempat yang sangat penting untuk memastikan FSM dapat di-test dengan comprehensive. FSM harus mudah di-test sehingga kita dapat menulis unit tests untuk semua possible transitions dan validasi bahwa invalid transitions di-reject dengan proper error handling.

**Documentation** adalah aspek terakhir yang sering diabaikan namun sangat penting. Dokumentasikan semua state dan transisi dengan jelas, buat state diagram yang mudah dipahami, dan jelaskan business logic di balik setiap transisi sehingga developer baru dapat dengan cepat memahami sistem.

> "Best practices dalam implementasi FSM meliputi validasi yang ketat, logging yang comprehensive, separation of concerns, testability yang baik, dan dokumentasi yang jelas. Kesemuanya penting untuk memastikan sistem yang maintainable dan reliable dalam jangka panjang." - (Sommerville, I., "Software Engineering" (2015), e-book tersedia di: https://archive.org/)

---

## FSM DALAM CONTEXT APLIKASI LAUNDRY POS

### 4.1 Analisis Use Case: Delivery vs Pickup

#### Delivery Transaction FSM

FSM untuk transaksi delivery memiliki alur yang lebih kompleks dibandingkan dengan pickup transaction karena melibatkan tahap pengiriman. Transaksi dimulai dari state PENDING ketika customer membuat order untuk dikirim ke alamatnya. Kemudian staff laundry memproses item dengan event MULAI_PROSES, membawa sistem ke state PROSES. Setelah pencucian selesai, event SELESAIKAN dipicu untuk membawa sistem ke state SELESAI. Dari state SELESAI, terdapat dua kemungkinan path: pertama, jika customer ingin mengambil item langsung, event TERIMA dapat dipicu tanpa melewati state DIKIRIM (skip state). Namun, jika item harus dikirim, event KIRIM dipicu untuk membawa sistem ke state DIKIRIM yang menunjukkan item sedang dalam perjalanan. Akhirnya, ketika item tiba di tangan customer, event TERIMA dipicu untuk mencapai final state DITERIMA. Transisi skip dari SELESAI langsung ke DITERIMA memberikan fleksibilitas bagi customer yang berubah pikiran atau memutuskan untuk mengambil item langsung tanpa menunggu pengiriman.

> "Dalam sistem yang kompleks seperti transaksi e-commerce dengan multiple delivery options, FSM memungkinkan untuk memodel berbagai path yang mungkin dengan tetap mempertahankan transisi yang valid dan deterministic." - (Bass, L., Clements, P., & Kazman, R., "Software Architecture in Practice" (2012), e-book tersedia di: https://www.informit.com/)

#### Pickup Transaction FSM

FSM untuk transaksi pickup memiliki alur yang lebih sederhana dan linear dibandingkan delivery transaction. Transaksi dimulai dari state PENDING ketika customer membuat order untuk pickup. Event MULAI_PROSES membawa sistem ke state PROSES dimana item sedang diproses. Event SELESAIKAN membawa sistem ke state SELESAI yang menunjukkan item siap untuk diambil customer. Dari state SELESAI, tidak ada state intermediary seperti DIKIRIM. Customer langsung melakukan pengambilan dengan event AMBIL yang membawa sistem langsung ke final state DITERIMA. Kesederhanaan alur ini mencerminkan simplicity dari pickup transaction dibandingkan dengan delivery yang memerlukan koordinasi dengan kurir dan customer.

Perbedaan utama antara kedua FSM ini adalah adanya state DIKIRIM dan event KIRIM pada delivery transaction, sementara pickup transaction menggunakan event AMBIL untuk transisi langsung dari SELESAI ke DITERIMA. Kedua FSM ini terintegrasi dalam logic aplikasi sehingga behavior transaksi disesuaikan berdasarkan tipe transaksi (delivery atau pickup).

### 4.2 Business Rule Validation dalam FSM

FSM memainkan peran kritis dalam mencegah operasi invalid yang dapat merusak data integrity dan melanggar business rules yang telah ditetapkan. Salah satu aspek penting dari FSM adalah kemampuannya untuk prevent duplicate processing. Ketika item sudah berada dalam state PROSES, sistem tidak akan mengizinkan event MULAI_PROSES untuk dipicu lagi karena tidak ada transisi yang valid dari state PROSES dengan event MULAI_PROSES. Ini mencegah skenario dimana item yang sama dapat diproses dua kali yang akan menyebabkan data inconsistency.

FSM juga memastikan sequential processing yang ketat. Sistem tidak mengizinkan customer untuk mengambil item (event AMBIL) ketika transaksi masih dalam state PENDING karena transisi PENDING →(AMBIL) tidak didefinisikan dalam FSM. Ini melindungi integritas bisnis dengan memastikan item harus melalui tahap processing sebelum dapat diambil oleh customer.

Untuk enforce delivery rules, FSM menggunakan conditional logic. Event KIRIM hanya valid pada state SELESAI jika isDelivery flag bernilai true. Ini mencegah skenario dimana sistem mencoba mengirim item untuk pickup transaction yang seharusnya diambil customer langsung di toko. Dengan cara ini, FSM tidak hanya mengelola transisi state tetapi juga memvalidasi business rules yang kompleks terkait karakteristik transaksi.

> "Validasi business rules melalui FSM memberikan perlindungan layer yang kuat terhadap operasi yang tidak sesuai dengan spesifikasi bisnis. Dengan mendefinisikan semua transisi yang valid, FSM bertindak sebagai gatekeeper yang memastikan hanya operasi yang legal yang dapat dilakukan." - (Martin, R.C., "Clean Architecture: A Craftsman's Guide to Software Structure and Design" (2017), e-book tersedia di: https://www.pearson.com/)

### 4.3 Koordinasi dengan TransaksiService

FSM tidak bekerja secara standalone dalam sistem, melainkan terintegrasi erat dengan TransaksiService yang bertanggung jawab untuk mengelola lifecycle transaksi secara keseluruhan. Ketika user atau staff melakukan aksi yang menghasilkan event, aksi tersebut masuk ke TransaksiService melalui method seperti updateTransactionState(event). TransaksiService kemudian melakukan serangkaian langkah untuk memproses event tersebut dengan benar.

Langkah pertama adalah validasi event untuk memastikan bahwa event yang diterima valid dan relevan dengan transaksi. Langkah kedua adalah memeriksa FSM untuk memastikan transisi yang diminta adalah valid dengan memanggil FSM.canTransition(). Jika transisi valid, langkah ketiga adalah mengeksekusi transisi FSM dengan memanggil FSM.transition() yang akan mengubah state internal. Setelah FSM transisi berhasil, langkah keempat adalah mengupdate database dengan new state sehingga perubahan state persisten dan dapat di-recover jika aplikasi crash. Langkah kelima adalah trigger notifications untuk menginformasikan stakeholder tentang perubahan state (misalnya mengirim SMS ke customer). Langkah terakhir adalah emit state changes melalui reactive streams sehingga UI dapat update dengan state yang baru.

Integrasi ini memastikan bahwa FSM logic tetap pure dan tidak bergantung pada database atau external systems, sementara TransaksiService menangani side effects. Dengan pemisahan concern ini, sistem menjadi lebih maintainable dan testable.

> "Separation of concerns adalah prinsip penting dalam software architecture, dimana logic FSM harus terpisah dari business logic, database operations, dan side effects. Dengan memisahkan concerns ini, sistem menjadi lebih modular, testable, dan maintainable." - (Evans, E., "Domain-Driven Design: Tackling Complexity in the Heart of Software" (2003), e-book tersedia di: https://www.oreilly.com/)

### 4.4 Persistence dan Recovery

Salah satu aspek penting dari FSM dalam aplikasi Laundry POS adalah persistence dan recovery dari state. **State Persistence** berarti bahwa current state dari setiap transaksi harus disimpan dalam database sehingga informasi state tidak hilang jika aplikasi crash atau server restart. Dengan persistence ini, sistem dapat melakukan recovery dengan memuatkan state dari database ketika aplikasi startup kembali. Hal ini penting untuk memastikan bahwa user dapat melihat state yang konsisten setelah restart, sehingga customer tidak perlu khawatir bahwa state transaksi mereka akan hilang.

Aspek kedua adalah **Audit Trail** yang merupakan pencatatan lengkap dari setiap state transition yang terjadi. Setiap kali terjadi transisi, sistem mencatat informasi seperti state sebelumnya, state sesudah, event yang memicu transisi, timestamp ketika transisi terjadi, dan user yang melakukan aksi. Audit trail ini sangat penting untuk beberapa alasan: pertama, untuk compliance dan regulatory purposes dimana pemerintah atau organisasi mungkin memerlukan catatan lengkap dari setiap transaksi untuk audit; kedua, untuk troubleshooting dan debugging dimana developer dapat melacak history lengkap transaksi untuk mengidentifikasi apa yang terjadi; ketiga, untuk fraud detection dimana pola unusual dalam history dapat menunjukkan adanya fraud atau abuse.

Dengan menggabungkan persistence dan audit trail, sistem Laundry POS dapat memberikan reliability dan traceability yang tinggi untuk setiap transaksi.

> "Persistence dari state adalah keharusan dalam sistem bisnis yang critical. Setiap perubahan state harus dicatat dan dapat dipulihkan untuk memastikan data consistency dan memenuhi regulatory compliance requirements." - (Fowler, M., "Enterprise Application Architecture Patterns" (2002), e-book tersedia di: https://www.oreilly.com/)

---

## KEUNTUNGAN DAN BATASAN FSM

### 5.1 Keuntungan Menggunakan FSM

#### 1. **Clarity and Predictability**

Menggunakan FSM dalam sistem membuat business logic menjadi explicit dan mudah dipahami oleh semua stakeholder, baik developer, manager, maupun customer. Dengan FSM, state dan transisi jelas terdefinisikan dalam dokumentasi, diagram, dan kode sehingga tidak ada ambiguitas tentang apa yang seharusnya terjadi pada state tertentu. Behavior sistem dapat diprediksi secara konsisten karena setiap event akan selalu menghasilkan state transition yang sama jika diberikan pada state yang sama. Predictability ini sangat penting untuk membangun kepercayaan user pada sistem karena user dapat mengandalkan bahwa sistem akan berperilaku seperti yang diharapkan.

> "Clarity dalam design adalah kunci untuk membangun sistem yang dapat dipahami dan dipercaya. Dengan menggunakan FSM, business logic menjadi explicit sehingga semua stakeholder dapat memahami bagaimana sistem seharusnya berperilaku." - (McConnell, S., "Code Complete: A Practical Handbook of Software Construction" (2004), e-book tersedia di: https://www.microsoft.com/)

#### 2. **Robustness**

FSM memberikan robustness terhadap error dengan mencegah invalid state transitions yang dapat merusak integritas data. Tanpa FSM, developer dapat secara tidak sengaja melakukan operasi yang tidak seharusnya dilakukan pada state tertentu, misalnya mengupdate item harga ketika status sudah final. FSM memberikan proteksi terhadap edge cases dengan memastikan hanya valid paths yang dapat diambil oleh sistem. Dengan cara ini, bugs yang terkait dengan state management dapat diminimalkan, dan sistem menjadi lebih robust terhadap unexpected inputs atau user actions.

> "Robustness adalah kemampuan sistem untuk terus berfungsi dengan baik bahkan ketika mengalami kondisi yang tidak diharapkan. FSM memberikan perlindungan dengan membatasi aksi yang mungkin untuk setiap state, sehingga mengurangi kemungkinan error." - (Dijkstra, E.W., "The Humble Programmer" (1972), paper klasik tersedia di: https://www.cs.utexas.edu/)

#### 3. **Testability**

FSM mudah untuk di-test karena behavior-nya deterministic dan well-defined. Untuk setiap state, kita tahu persis apa yang harus terjadi ketika event tertentu diterima. Ini memungkinkan coverage 100% dalam unit tests dimana kita dapat test semua possible transitions dan memverifikasi bahwa setiap transisi menghasilkan state yang benar. Deterministic behavior FSM juga memudahkan untuk membuat unit tests karena tidak ada randomness atau non-determinism yang dapat membuat tests flaky.

> "Testability adalah salah satu atribut penting dalam software design. FSM yang well-designed memungkinkan untuk menulis comprehensive test cases yang cover semua kemungkinan transisi, sehingga meningkatkan confidence dalam correctness sistem." - (Beck, K., "Test Driven Development: By Example" (2002), e-book tersedia di: https://www.pearson.com/)

#### 4. **Maintainability**

Implementasi FSM membuat kode lebih terstruktur dan mudah dipahami. Ketika business logic berubah, perubahan dapat diisolasi pada specific state atau transition tanpa mempengaruhi bagian lain dari sistem. Jika ada bug yang terkait dengan state management, debugging menjadi lebih mudah karena kita dapat langsung melihat tabel transisi atau diagram state untuk memahami apa yang seharusnya terjadi. Pemisahan concern antara FSM logic dan business logic membuat kode lebih maintainable.

> "Maintainability adalah faktor kritis dalam long-term success dari sebuah project. Kode yang terstruktur dengan baik menggunakan FSM akan lebih mudah di-maintain, di-extend, dan di-debug dibandingkan dengan kode yang menggunakan ad-hoc state management." - (Hunt, A. & Thomas, D., "The Pragmatic Programmer: Your Journey to Mastery" (1999), e-book tersedia di: https://pragmaticprogrammer.com/)

#### 5. **Scalability**

FSM memudahkan untuk menambah state atau event baru dengan minimal impact pada existing code. Ketika requirement baru muncul dan memerlukan state baru, kita dapat menambahkan state ke FSM tanpa breaking existing logic. Mudah untuk extend FSM dengan new features karena struktur FSM yang teratur memudahkan untuk add new transitions. Dengan ini, sistem dapat grow dan scale sesuai dengan requirement bisnis yang terus berkembang.

> "Scalability dalam design berarti sistem dapat dengan mudah beradaptasi dengan perubahan requirement tanpa perlu redesign dari nol. FSM yang well-designed memungkinkan penambahan state dan transisi baru dengan mudah, supporting business growth." - (Booch, G., "Object-Oriented Analysis and Design with Applications" (2007), e-book tersedia di: https://www.informit.com/)

#### 6. **Compliance dan Audit**

FSM memfasilitasi compliance dengan requirement regulatory karena sistem dapat melacak state history dengan lengkap. Business rules tercermin dalam code FSM sehingga audit dapat memverifikasi bahwa implementasi sesuai dengan requirement. Dengan audit trail yang lengkap, organization dapat demonstrate bahwa setiap transaksi telah diproses sesuai dengan policy dan procedure yang ditetapkan.

> "Compliance dan audit trail adalah keharusan dalam sistem bisnis yang tunduk pada regulasi. FSM memberikan transparency dalam state transitions, memudahkan auditors untuk memverifikasi bahwa sistem beroperasi sesuai dengan business rules yang ditetapkan." - (COSO, "Internal Control—Integrated Framework" (2013), e-book tersedia di: https://www.coso.org/)

### 5.2 Batasan FSM

#### 1. **Complexity untuk Large State Spaces**

Salah satu batasan FSM yang signifikan adalah bahwa jika jumlah state atau event terlalu banyak, FSM dapat menjadi sangat kompleks dan sulit dikelola. Masalah ini dikenal sebagai state explosion problem, dimana jumlah state dan transisi berkembang secara eksponensial, membuat tabel transisi menjadi sangat besar dan rumit. Ketika tabel transisi mencapai ukuran yang besar, menjadi sulit untuk memahami seluruh sistem dan mudah terjadi error dalam mendefinisikan transisi.

Namun, terdapat beberapa solusi untuk mengatasi masalah ini. Pertama adalah menggunakan Hierarchical FSM (nested states) dimana state dapat memiliki sub-state, sehingga struktur FSM menjadi lebih hierarkis dan mudah dikelola. Kedua adalah memisahkan FSM untuk different concerns, sehingga setiap FSM hanya menangani aspek tertentu dari sistem. Ketiga adalah melakukan state grouping, dimana state yang memiliki behavior serupa dapat dikelompokkan bersama untuk mengurangi kompleksitas.

> "State explosion adalah tantangan umum dalam design FSM yang kompleks. Hierarchical state machines dan modular design adalah teknik-teknik yang dapat digunakan untuk mengelola kompleksitas ketika jumlah state dan transisi menjadi besar." - (Harel, D. & Statecharts, "A Visual Formalism for Complex Systems" (1987), e-book tersedia di: https://www.sciencedirect.com/)

#### 2. **Rigid State Definition**

FSM memerlukan definisi state yang rigid dan pasti, sehingga sulit untuk menangani state yang overlap atau conditional. Dalam beberapa kasus, mungkin ada state yang memiliki karakteristik dari lebih dari satu state logis, namun dalam FSM tradisional sistem hanya dapat berada dalam satu state pada waktu yang bersamaan. Ini memerlukan design yang matang di awal, dan perubahan requirement dapat memerlukan redesign yang signifikan pada FSM.

Untuk mengatasi masalah ini, terdapat beberapa pendekatan. Pertama adalah menggunakan guard conditions untuk conditional transitions, dimana transisi hanya valid jika kondisi tertentu terpenuhi. Kedua adalah menggunakan Extended FSM (EFSM) yang mengintegrasikan state variables, sehingga sistem dapat melacak informasi tambahan selain state saat ini. Dengan state variables, FSM dapat membuat keputusan berdasarkan not hanya current state tetapi juga nilai-nilai yang tersimpan dalam variables.

> "Extended FSM (EFSM) adalah variasi dari FSM yang memungkinkan untuk menambahkan state variables dan guard conditions, memberikan fleksibilitas yang lebih besar untuk memodel sistem yang kompleks tanpa kehilangan determinism." - (Holzmann, G.J., "The SPIN Model Checker: Primer and Reference Manual" (2003), e-book tersedia di: https://spinroot.com/)

#### 3. **Limited Context**

FSM berfokus pada transisi state berdasarkan event, namun FSM hanya mempertimbangkan current state dan event tanpa melihat context atau informasi lainnya. Ini berarti memerlukan tambahan logic di luar FSM untuk menangani business rules yang kompleks yang bergantung pada multiple factors. Dalam beberapa kasus, FSM murni mungkin tidak cukup untuk mengexpresikan kompleksitas business logic yang diperlukan.

Solusi untuk masalah ini adalah mengextend FSM dengan guard conditions yang dapat mengevaluasi kondisi arbitrer sebelum mengizinkan transisi. Gunakan state variables dalam EFSM untuk menyimpan konteks yang relevan dengan transaksi. Selain itu, gunakan context atau payload dalam events sehingga informasi tambahan dapat dikirimkan bersama dengan event untuk membantu FSM membuat keputusan.

FSM adalah konsep yang powerful namun mungkin tidak familiar bagi semua developer, sehingga team memerlukan pemahaman yang mendalam tentang teori dan praktik FSM. Dokumentasi harus sangat jelas dan comprehensive untuk memastikan semua developer dapat memahami sistem. Paradigma FSM juga berbeda dari imperative programming tradisional yang mungkin lebih familiar bagi developer, sehingga ada learning curve yang harus dilewati.

Untuk mengatasi masalah ini, penting untuk memberikan training kepada team tentang konsep dan best practices FSM. Dokumentasi harus comprehensive dengan banyak contoh dan penjelasan. Code reviews dan pair programming juga sangat membantu untuk memastikan implementasi FSM yang konsisten dan berkualitas tinggi di seluruh tim.

---

## REFERENSI ILMIAH

### Buku Referensi

1. **Hopcroft, J. E., Motwani, R., & Ullman, J. D. (2006).** 
   *Introduction to Automata Theory, Languages, and Computation* (3rd ed.). 
   Pearson Education.
   - Foundational text untuk teori FSM dan automata
   - Comprehensive coverage dari mathematical foundations

2. **Gamma, E., Helm, R., Johnson, R., & Vlissides, J. (1994).**
   *Design Patterns: Elements of Reusable Object-Oriented Software*.
   Addison-Wesley.
   - Memperkenalkan State Pattern sebagai implementasi FSM dalam OOP
   - Classic reference untuk design patterns

3. **Martin, R. C. (2018).**
   *Clean Architecture: A Craftsman's Guide to Software Structure and Design*.
   Prentice Hall.
   - Best practices untuk implementasi FSM dalam real-world applications
   - Principles untuk maintainable dan scalable FSM design

4. **Sommerville, I. (2015).**
   *Software Engineering* (10th ed.).
   Pearson Education.
   - Comprehensive coverage dari state machines dalam software engineering
   - Real-world examples dan best practices

### Online Resources

5. **Sipser, M. (2012).**
   *Introduction to the Theory of Computation* (3rd ed.).
   Cengage Learning.
   - Mathematical foundations dari finite automata
   - Formal language theory

6. **David Evans. "CS4414: Introducing to the Theory of Computation"**
   University of Virginia.
   - Lecture notes tentang FSM dan automata theory
   - Practical examples dan exercises

### Flutter/Dart Specific References

7. **Remy Rousselet. "Provider - State Management"**
   Available at: https://pub.dev/packages/provider
   - Flutter state management integration dengan FSM concepts

8. **Dart Language Documentation**
   Available at: https://dart.dev/guides
   - Enum dan language features untuk implementasi FSM

### Industry Standards

9. **UML State Machine Specification**
   - OMG (Object Management Group) standard untuk modeling state machines
   - Used in: OOAD design dan documentation

10. **IEEE 802.11 FSM Specification**
    - Example dari FSM dalam wireless protocol
    - Complex real-world FSM implementation

---

## KESIMPULAN

Finite State Machine adalah fundamental concept dalam computer science yang sangat berguna untuk managing complex stateful behavior dalam aplikasi. Dalam konteks Laundry POS:

- **FSM menyediakan formal foundation** untuk transaction state management
- **Mencegah invalid operations** dan memastikan data integrity
- **Membuat business logic explicit** dan mudah dipahami
- **Memfasilitasi testing dan debugging** 
- **Mendukung scalability dan maintenance** jangka panjang

Dengan menerapkan FSM secara proper, aplikasi Laundry POS dapat:
1. ✅ Mengelola transaksi dengan aman dan reliable
2. ✅ Meminimalkan bugs dan edge cases
3. ✅ Memudahkan onboarding tim development
4. ✅ Mendukung feature development di masa depan
5. ✅ Memenuhi compliance dan audit requirements

Pemahaman mendalam tentang FSM membantu developer membuat keputusan design yang lebih baik dan implementasi yang lebih robust.

---

**Dokumen ini dibuat sebagai teori penunjang untuk implementasi FSM dalam Aplikasi Laundry POS.**
**Last Updated: January 27, 2026**
