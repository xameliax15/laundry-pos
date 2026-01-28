# BAB III TEORI PENUNJANG KERJA PRAKTIK

## III.1 Teori Penunjang

### Konsep atau Teori yang Digunakan dalam Pekerjaan Kerja Praktik

Pengembangan aplikasi kasir Trias Laundry menggunakan beberapa konsep dan teori fundamental yang menjadi landasan dalam perancangan dan implementasi sistem. Konsep utama yang digunakan adalah **Flexible Management System (FMS)** yang merupakan pendekatan manajemen sistem yang fleksibel dan adaptif terhadap berbagai skenario operasional. FMS memungkinkan sistem untuk menangani variasi alur proses tanpa perlu perubahan struktural yang signifikan, sehingga cocok diterapkan pada lingkungan bisnis yang dinamis seperti usaha laundry. Konsep ini diterapkan pada pengelolaan alur transaksi, status pesanan, dan koordinasi antar unit kerja untuk memastikan konsistensi dan efisiensi operasional.

Teori **Software Engineering** menjadi landasan dalam metodologi pengembangan aplikasi, khususnya pendekatan **Agile Development** yang memungkinkan pengembangan iteratif dan adaptif terhadap perubahan kebutuhan. Prinsip-prinsip software engineering seperti modularitas, reusability, dan maintainability diterapkan dalam struktur kode dan arsitektur aplikasi. Teori **Database Management System** digunakan dalam perancangan struktur data yang efisien dan normalisasi database untuk menghindari redundansi dan memastikan integritas data. Konsep **Cloud Computing** diterapkan melalui penggunaan Supabase sebagai platform Backend-as-a-Service (BaaS) yang menyediakan infrastruktur database, autentikasi, dan storage secara cloud-based.

Teori **User Interface/User Experience (UI/UX) Design** menjadi acuan dalam perancangan antarmuka pengguna yang user-friendly dan intuitif. Prinsip-prinsip desain seperti consistency, feedback, dan error prevention diterapkan untuk memastikan pengalaman pengguna yang optimal. Konsep **Role-Based Access Control (RBAC)** digunakan dalam implementasi sistem autentikasi dan otorisasi untuk memastikan setiap pengguna hanya dapat mengakses fitur sesuai dengan peran dan tanggung jawabnya. Teori **State Management** dalam pengembangan aplikasi Flutter digunakan untuk mengelola state aplikasi secara efisien dan memastikan konsistensi data antar komponen.

### Keterkaitan Teori dengan Pekerjaan yang Dilakukan

Keterkaitan teori Flexible Management System (FMS) dengan pekerjaan yang dilakukan sangat erat karena algoritma FMS menjadi inti dari pengelolaan alur transaksi dalam aplikasi. FMS memungkinkan sistem untuk menangani berbagai skenario transaksi seperti pembayaran di awal atau akhir, pengambilan di tempat atau pengiriman, serta berbagai kombinasi status pesanan tanpa perlu membuat logika terpisah untuk setiap skenario. Implementasi FMS dalam aplikasi memungkinkan fleksibilitas dalam pengelolaan status transaksi, di mana sistem dapat beradaptasi dengan perubahan status yang terjadi secara dinamis sesuai dengan kondisi operasional.

Teori Software Engineering terkait langsung dengan metodologi pengembangan yang digunakan, di mana pendekatan Agile memungkinkan pengembangan iteratif berdasarkan feedback dari pengguna. Prinsip modularitas memungkinkan pengembangan fitur-fitur aplikasi secara terpisah namun terintegrasi, seperti modul transaksi, pelanggan, pembayaran, dan dashboard. Teori Database Management System terkait dengan perancangan struktur database yang efisien untuk menyimpan data transaksi, pelanggan, dan pengguna, serta implementasi relasi antar tabel untuk memastikan integritas data.

Konsep Cloud Computing melalui Supabase memungkinkan aplikasi dapat diakses dari berbagai perangkat dan lokasi tanpa perlu infrastruktur server sendiri. Teori UI/UX Design terkait dengan perancangan antarmuka yang mudah digunakan oleh berbagai level pengguna, dari kasir hingga owner. Konsep RBAC memastikan keamanan sistem dengan membatasi akses sesuai peran pengguna, sementara State Management memastikan konsistensi data dalam aplikasi Flutter yang kompleks.

### Teori yang Benar-Benar Dipakai dalam Pelaksanaan Kerja Praktik

Teori yang benar-benar dipakai dalam pelaksanaan kerja praktik adalah **Flexible Management System (FMS)** yang diimplementasikan secara langsung dalam algoritma pengelolaan alur transaksi. FMS diterapkan pada sistem status transaksi yang memungkinkan perpindahan status yang fleksibel namun tetap terkontrol, seperti dari pending ke proses, proses ke selesai, selesai ke dikirim atau diterima, dengan validasi yang memastikan alur yang logis. Algoritma FMS juga diterapkan pada pengelolaan pembayaran yang dapat dilakukan di berbagai tahap transaksi sesuai dengan skenario operasional, serta pada sistem penugasan kurir yang dapat dilakukan secara otomatis atau manual tergantung kondisi.

**Prinsip Software Engineering** diterapkan dalam struktur pengembangan aplikasi, di mana kode dibagi menjadi modul-modul yang terpisah seperti service layer untuk logika bisnis, model layer untuk struktur data, dan UI layer untuk antarmuka pengguna. **Database Normalization** diterapkan dalam perancangan tabel database untuk menghindari redundansi data dan memastikan integritas referensial. **RESTful API Architecture** digunakan dalam komunikasi antara aplikasi Flutter dengan Supabase, meskipun Supabase menyediakan SDK yang menyederhanakan implementasi.

**State Management Pattern** dalam Flutter diterapkan menggunakan setState dan FutureBuilder untuk mengelola state aplikasi dan menangani operasi asynchronous. **Authentication and Authorization Theory** diterapkan melalui Supabase Auth yang menyediakan sistem autentikasi berbasis email/password dengan session management. **File Storage Management** diterapkan melalui Supabase Storage untuk menyimpan foto laundry dan bukti pembayaran dengan manajemen akses yang terkontrol.

## III.2 Peralatan Pembangunan / Tools

### Perangkat Lunak yang Digunakan

Perangkat lunak utama yang digunakan dalam pengembangan aplikasi kasir Trias Laundry adalah **Flutter SDK** versi terbaru yang menyediakan framework untuk pengembangan aplikasi cross-platform. Flutter memungkinkan pengembangan aplikasi web dan mobile dengan codebase yang sama, sehingga efisien dalam maintenance dan pengembangan. **Dart Programming Language** digunakan sebagai bahasa pemrograman utama dalam pengembangan aplikasi, yang merupakan bahasa yang dirancang khusus untuk Flutter dengan fitur modern seperti async/await, null safety, dan type inference.

**Supabase** digunakan sebagai platform Backend-as-a-Service (BaaS) yang menyediakan berbagai layanan terintegrasi. Supabase Auth digunakan untuk manajemen autentikasi dan otorisasi pengguna, Supabase Database (PostgreSQL) digunakan untuk penyimpanan data transaksi, pelanggan, dan pengguna, serta Supabase Storage digunakan untuk penyimpanan file seperti foto laundry dan bukti pembayaran. **Supabase Flutter SDK** digunakan untuk integrasi aplikasi Flutter dengan layanan Supabase.

**Cursor** digunakan sebagai Integrated Development Environment (IDE) untuk pengembangan aplikasi. Cursor menyediakan fitur-fitur modern seperti code completion, syntax highlighting, debugging, dan Git integration yang memudahkan proses pengembangan. **Git** digunakan untuk version control dalam pengelolaan source code aplikasi, memungkinkan tracking perubahan, collaboration, dan rollback jika diperlukan.

**Cloudflare Pages** digunakan sebagai platform hosting untuk aplikasi web. Cloudflare Pages menyediakan hosting gratis dengan fitur seperti automatic deployment, CDN global, dan SSL certificate yang memastikan aplikasi dapat diakses dengan cepat dan aman dari berbagai lokasi. **Google Chrome** digunakan sebagai browser untuk testing dan debugging aplikasi web selama proses pengembangan.

### Perangkat Keras Pendukung

Perangkat keras yang digunakan sebagai pendukung pengembangan aplikasi meliputi **komputer/laptop** dengan spesifikasi minimal processor dual-core, RAM 8GB, dan storage SSD untuk memastikan performa yang optimal dalam menjalankan Flutter SDK dan IDE. Komputer digunakan untuk coding, testing, dan debugging aplikasi baik dalam mode development maupun production.

**Smartphone Android** digunakan untuk testing aplikasi pada platform mobile, memastikan aplikasi dapat berjalan dengan baik pada perangkat mobile selain web. **Koneksi internet** yang stabil diperlukan untuk akses ke Supabase, Cloudflare, dan berbagai resources online lainnya selama proses pengembangan. Internet juga diperlukan untuk deployment aplikasi dan testing fitur cloud-based seperti autentikasi dan storage.

**Server/Cloud Infrastructure** yang disediakan oleh Supabase dan Cloudflare digunakan sebagai infrastruktur backend dan hosting. Meskipun tidak dimiliki secara fisik, infrastruktur cloud ini merupakan komponen penting dalam operasional aplikasi dan memerlukan konfigurasi serta monitoring selama pengembangan dan deployment.

### Fungsi Masing-Masing Tools dalam Pekerjaan Kerja Praktik

**Flutter SDK** berfungsi sebagai framework utama untuk pengembangan antarmuka pengguna dan logika aplikasi. Flutter memungkinkan pembuatan UI yang responsif dan modern menggunakan widget system, serta menyediakan tools untuk hot reload yang mempercepat proses development. Flutter juga menyediakan package ecosystem yang luas untuk berbagai kebutuhan seperti image picker, path provider, dan state management.

**Dart Programming Language** berfungsi sebagai bahasa pemrograman untuk menulis seluruh kode aplikasi. Dart menyediakan fitur-fitur seperti strong typing, garbage collection, dan async programming yang memudahkan pengembangan aplikasi yang kompleks. Dart juga terintegrasi dengan baik dengan Flutter, memungkinkan optimasi performa dan developer experience yang optimal.

**Supabase** berfungsi sebagai backend infrastructure yang menyediakan database, autentikasi, dan storage tanpa perlu setup server sendiri. Supabase Auth menyediakan sistem autentikasi yang aman dengan fitur seperti email verification, password reset, dan session management. Supabase Database menyediakan PostgreSQL dengan fitur seperti Row Level Security (RLS) untuk keamanan data, real-time subscriptions untuk update data secara real-time, dan REST API otomatis. Supabase Storage menyediakan penyimpanan file dengan manajemen akses yang fleksibel melalui policy system.

**Cursor IDE** berfungsi sebagai environment untuk menulis, mengedit, dan mengelola kode aplikasi. Cursor menyediakan fitur seperti IntelliSense untuk code completion, integrated terminal untuk menjalankan commands, dan debugging tools untuk troubleshooting. Cursor juga terintegrasi dengan Git untuk version control dan berbagai extensions untuk meningkatkan produktivitas development.

**Git** berfungsi untuk version control dalam mengelola perubahan source code. Git memungkinkan tracking history perubahan, branching untuk pengembangan fitur paralel, dan merging untuk menggabungkan perubahan. Git juga memungkinkan collaboration dan backup code secara terdistribusi.

**Cloudflare Pages** berfungsi sebagai platform hosting untuk deploy aplikasi web. Cloudflare Pages menyediakan automatic deployment dari Git repository, global CDN untuk distribusi konten yang cepat, dan SSL certificate otomatis untuk keamanan. Cloudflare Pages juga menyediakan analytics dan monitoring untuk tracking performa aplikasi.

**Google Chrome** berfungsi sebagai browser untuk testing dan debugging aplikasi web selama development. Chrome Developer Tools menyediakan berbagai fitur seperti console untuk debugging JavaScript/Dart, network tab untuk monitoring API calls, dan performance profiling untuk optimasi. Chrome juga digunakan untuk testing responsive design dan compatibility dengan berbagai ukuran layar.

---

## Referensi Teori

1. **Flexible Management System (FMS)**
   - Konsep manajemen sistem yang fleksibel dan adaptif untuk menangani variasi proses bisnis
   - Diterapkan pada pengelolaan alur transaksi dan status pesanan

2. **Software Engineering Principles**
   - Modularitas, reusability, dan maintainability dalam struktur aplikasi
   - Agile Development methodology untuk pengembangan iteratif

3. **Database Management System**
   - Normalisasi database untuk efisiensi dan integritas data
   - Relational database design dengan PostgreSQL

4. **Cloud Computing & Backend-as-a-Service (BaaS)**
   - Supabase sebagai platform cloud untuk database, auth, dan storage
   - Scalability dan availability melalui cloud infrastructure

5. **User Interface/User Experience (UI/UX) Design**
   - Prinsip consistency, feedback, dan error prevention
   - Role-based interface design untuk berbagai level pengguna

6. **State Management in Flutter**
   - Pengelolaan state aplikasi untuk konsistensi data
   - Async programming dengan FutureBuilder dan async/await

7. **Authentication and Authorization**
   - Role-Based Access Control (RBAC) untuk keamanan sistem
   - Session management dan secure authentication flow

---

*Catatan: Untuk referensi jurnal akademik spesifik tentang FMS dan sistem manajemen laundry, disarankan untuk mencari di database jurnal seperti Google Scholar, IEEE Xplore, atau ScienceDirect dengan kata kunci "Flexible Management System", "Laundry Management System", atau "POS System for Service Industry".*
