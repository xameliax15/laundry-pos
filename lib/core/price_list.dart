class PriceList {
  // Laundry Kiloan (per kg)
  static const double laundryReguler = 6000;
  static const double laundrySemiQuick = 6500;
  static const double laundryQuick = 7500;
  static const double laundryExpress = 10000;
  static const double laundrySuperExpress = 15000;
  static const double setrikaSaja = 4500;
  static const double cuciLipat = 5000;
  static const int minKiloan = 1; // Minimum 1kg

  // Sepatu, Jaket & Helm
  static const double sepatuSneakers = 20000;
  static const double sepatuKulit = 25000;
  static const double jaketKulit = 30000;
  static const double helm = 20000;

  // Tas, Ransel
  static const double tasKecil = 15000;
  static const double tasSedang = 20000;
  static const double tasBesar = 25000;
  static const double tasCarrier = 50000;

  // Boneka
  static const double bonekaKecil = 15000;
  static const double bonekaSedang = 20000;
  static const double bonekaBesar = 35000;
  static const double bonekaJumbo = 50000;

  // Karpet (per m²)
  static const double karpetStandar = 13000;
  static const double karpetTipis = 10000;
  static const double karpetTebal = 15000;

  // Get harga berdasarkan jenis layanan dan item
  static double getHarga({
    required String jenisLayanan,
    required String jenisBarang,
    String? ukuran,
    double? berat, // untuk kiloan
    double? luas, // untuk karpet (m²)
  }) {
    switch (jenisLayanan) {
      case 'laundry_kiloan':
        switch (jenisBarang) {
          case 'reguler':
            return laundryReguler * (berat ?? minKiloan);
          case 'semi_quick':
            return laundrySemiQuick * (berat ?? minKiloan);
          case 'quick':
            return laundryQuick * (berat ?? minKiloan);
          case 'express':
            return laundryExpress * (berat ?? minKiloan);
          case 'super_express':
            return laundrySuperExpress * (berat ?? minKiloan);
          case 'setrika_saja':
            return setrikaSaja * (berat ?? minKiloan);
          case 'cuci_lipat':
            return cuciLipat * (berat ?? minKiloan);
          default:
            return laundryReguler * (berat ?? minKiloan);
        }

      case 'sepatu':
        switch (jenisBarang) {
          case 'sneakers':
            return sepatuSneakers;
          case 'kulit':
            return sepatuKulit;
          default:
            return sepatuSneakers;
        }

      case 'jaket':
        if (jenisBarang == 'kulit') {
          return jaketKulit;
        }
        return 0; // Jaket biasa masuk kiloan

      case 'helm':
        return helm;

      case 'tas':
        switch (ukuran) {
          case 'kecil':
            return tasKecil;
          case 'sedang':
            return tasSedang;
          case 'besar':
            return tasBesar;
          case 'carrier':
            return tasCarrier;
          default:
            return tasKecil;
        }

      case 'boneka':
        switch (ukuran) {
          case 'kecil':
            return bonekaKecil;
          case 'sedang':
            return bonekaSedang;
          case 'besar':
            return bonekaBesar;
          case 'jumbo':
            return bonekaJumbo;
          default:
            return bonekaKecil;
        }

      case 'karpet':
        switch (jenisBarang) {
          case 'standar':
            return karpetStandar * (luas ?? 1);
          case 'tipis':
            return karpetTipis * (luas ?? 1);
          case 'tebal':
          case 'mushola':
            return karpetTebal * (luas ?? 1);
          default:
            return karpetStandar * (luas ?? 1);
        }

      default:
        return 0;
    }
  }

  // List jenis layanan
  static List<String> getJenisLayanan() {
    return [
      'laundry_kiloan',
      'sepatu',
      'jaket',
      'helm',
      'tas',
      'boneka',
      'karpet',
    ];
  }

  // List opsi untuk laundry kiloan
  static List<Map<String, dynamic>> getOpsiLaundryKiloan() {
    return [
      {'value': 'reguler', 'label': 'Reguler (3 Hari)', 'harga': laundryReguler},
      {'value': 'semi_quick', 'label': 'Semi-Quick (2 Hari)', 'harga': laundrySemiQuick},
      {'value': 'quick', 'label': 'Quick (1 Hari)', 'harga': laundryQuick},
      {'value': 'express', 'label': 'Express (5 Jam)', 'harga': laundryExpress},
      {'value': 'super_express', 'label': 'Super-Express (2 Jam)', 'harga': laundrySuperExpress},
      {'value': 'setrika_saja', 'label': 'Setrika Saja (2 Jam)', 'harga': setrikaSaja},
      {'value': 'cuci_lipat', 'label': 'Cuci Lipat (2 Jam)', 'harga': cuciLipat},
    ];
  }

  // List ukuran untuk tas/boneka
  static List<String> getUkuran() {
    return ['kecil', 'sedang', 'besar'];
  }

  // List ukuran boneka (termasuk jumbo)
  static List<String> getUkuranBoneka() {
    return ['kecil', 'sedang', 'besar', 'jumbo'];
  }

  // List ukuran tas (termasuk carrier)
  static List<String> getUkuranTas() {
    return ['kecil', 'sedang', 'besar', 'carrier'];
  }
}




