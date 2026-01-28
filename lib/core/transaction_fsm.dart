/// Finite State Machine untuk Transaksi Laundry
/// Mengimplementasikan FSM formal untuk mengelola state transaksi
enum TransactionState {
  pending,
  proses,
  selesai,
  dikirim,
  diterima,
}

enum TransactionEvent {
  mulaiProses,
  selesaikan,
  kirim,
  terima,
  ambil,
}

/// Finite State Machine untuk Transaksi
class TransactionFSM {
  final bool isDelivery;
  TransactionState _currentState;

  TransactionFSM({
    required TransactionState initialState,
    this.isDelivery = false,
  }) : _currentState = initialState;

  TransactionState get currentState => _currentState;

  /// State Transition Table (Transisi yang valid)
  Map<TransactionState, Map<TransactionEvent, TransactionState>> 
      get _transitionTable {
    if (isDelivery) {
      // FSM untuk transaksi delivery
      return {
        TransactionState.pending: {
          TransactionEvent.mulaiProses: TransactionState.proses,
        },
        TransactionState.proses: {
          TransactionEvent.selesaikan: TransactionState.selesai,
        },
        TransactionState.selesai: {
          TransactionEvent.kirim: TransactionState.dikirim,
          TransactionEvent.terima: TransactionState.diterima, // Skip dikirim (fleksibel)
        },
        TransactionState.dikirim: {
          TransactionEvent.terima: TransactionState.diterima,
        },
        TransactionState.diterima: {}, // Final state, tidak ada transisi
      };
    } else {
      // FSM untuk transaksi pickup (ambil di tempat)
      return {
        TransactionState.pending: {
          TransactionEvent.mulaiProses: TransactionState.proses,
        },
        TransactionState.proses: {
          TransactionEvent.selesaikan: TransactionState.selesai,
        },
        TransactionState.selesai: {
          TransactionEvent.ambil: TransactionState.diterima,
        },
        TransactionState.diterima: {}, // Final state
      };
    }
  }

  /// Mendapatkan list event yang valid untuk state saat ini
  List<TransactionEvent> getAvailableEvents() {
    final transitions = _transitionTable[_currentState];
    if (transitions == null) return [];
    return transitions.keys.toList();
  }

  /// Mendapatkan list state berikutnya yang valid
  List<TransactionState> getNextStates() {
    final transitions = _transitionTable[_currentState];
    if (transitions == null) return [];
    return transitions.values.toList();
  }

  /// Memproses event dan melakukan transisi state
  /// Returns: true jika transisi berhasil, false jika tidak valid
  bool processEvent(TransactionEvent event) {
    final transitions = _transitionTable[_currentState];
    
    if (transitions == null) {
      return false; // State tidak memiliki transisi
    }

    final nextState = transitions[event];
    if (nextState == null) {
      return false; // Event tidak valid untuk state saat ini
    }

    _currentState = nextState;
    return true;
  }

  /// Memvalidasi apakah transisi dari state saat ini ke state target valid
  bool canTransitionTo(TransactionState targetState) {
    final transitions = _transitionTable[_currentState];
    if (transitions == null) return false;
    
    return transitions.values.contains(targetState);
  }

  /// Melakukan transisi langsung ke state target (jika valid)
  bool transitionTo(TransactionState targetState) {
    if (!canTransitionTo(targetState)) {
      return false;
    }

    _currentState = targetState;
    return true;
  }

  /// Cek apakah state saat ini adalah final state
  bool get isFinalState {
    return _currentState == TransactionState.diterima;
  }

  /// Konversi dari string status ke TransactionState
  static TransactionState fromString(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return TransactionState.pending;
      case 'proses':
        return TransactionState.proses;
      case 'selesai':
        return TransactionState.selesai;
      case 'dikirim':
        return TransactionState.dikirim;
      case 'diterima':
        return TransactionState.diterima;
      default:
        throw ArgumentError('Invalid status: $status');
    }
  }

  /// Konversi dari TransactionState ke string status
  static String stateToString(TransactionState state) {
    switch (state) {
      case TransactionState.pending:
        return 'pending';
      case TransactionState.proses:
        return 'proses';
      case TransactionState.selesai:
        return 'selesai';
      case TransactionState.dikirim:
        return 'dikirim';
      case TransactionState.diterima:
        return 'diterima';
    }
  }

  /// Mendapatkan deskripsi state
  String getStateDescription() {
    switch (_currentState) {
      case TransactionState.pending:
        return 'Menunggu untuk diproses';
      case TransactionState.proses:
        return 'Sedang dalam proses pencucian';
      case TransactionState.selesai:
        return isDelivery 
            ? 'Siap untuk dikirim' 
            : 'Siap untuk diambil';
      case TransactionState.dikirim:
        return 'Sedang dalam pengiriman';
      case TransactionState.diterima:
        return 'Pesanan telah diterima pelanggan';
    }
  }

  /// Mendapatkan deskripsi event
  static String getEventDescription(TransactionEvent event) {
    switch (event) {
      case TransactionEvent.mulaiProses:
        return 'Mulai proses pencucian';
      case TransactionEvent.selesaikan:
        return 'Selesaikan pencucian';
      case TransactionEvent.kirim:
        return 'Kirim pesanan';
      case TransactionEvent.terima:
        return 'Terima pesanan';
      case TransactionEvent.ambil:
        return 'Ambil pesanan';
    }
  }

  /// Clone FSM untuk keperluan testing atau backup
  TransactionFSM clone() {
    return TransactionFSM(
      initialState: _currentState,
      isDelivery: isDelivery,
    );
  }

  @override
  String toString() {
    return 'TransactionFSM(state: ${stateToString(_currentState)}, '
           'isDelivery: $isDelivery, '
           'isFinal: $isFinalState)';
  }
}

/// State Machine Actions - Callbacks yang dipanggil saat transisi
abstract class TransactionFSMActions {
  /// Dipanggil sebelum transisi
  Future<bool> onBeforeTransition(
    TransactionState from,
    TransactionState to,
    TransactionEvent event,
  );

  /// Dipanggil setelah transisi
  Future<void> onAfterTransition(
    TransactionState from,
    TransactionState to,
    TransactionEvent event,
  );

  /// Dipanggil saat transisi gagal
  Future<void> onTransitionFailed(
    TransactionState current,
    TransactionEvent event,
    String reason,
  );
}

/// FSM dengan Actions - Extended FSM dengan callback
class TransactionFSMWithActions extends TransactionFSM {
  final TransactionFSMActions? actions;

  TransactionFSMWithActions({
    required super.initialState,
    super.isDelivery,
    this.actions,
  });

  @override
  bool processEvent(TransactionEvent event) {
    // For sync version, skip actions callbacks
    // Use processEventAsync for async actions
    return super.processEvent(event);
  }

  /// Async version dengan actions callback
  Future<bool> processEventAsync(TransactionEvent event) async {
    final fromState = currentState;
    final availableEvents = getAvailableEvents();

    if (!availableEvents.contains(event)) {
      await actions?.onTransitionFailed(
        fromState,
        event,
        'Event tidak valid untuk state saat ini',
      );
      return false;
    }

    final transitions = _transitionTable[fromState];
    if (transitions == null) {
      await actions?.onTransitionFailed(
        fromState,
        event,
        'Tidak ada transisi yang tersedia',
      );
      return false;
    }

    final toState = transitions[event];
    if (toState == null) {
      await actions?.onTransitionFailed(
        fromState,
        event,
        'Event tidak menghasilkan state target',
      );
      return false;
    }

    // Call before transition
    final canProceed = await (actions?.onBeforeTransition(fromState, toState, event) 
        ?? Future.value(true));
    
    if (!canProceed) {
      await actions?.onTransitionFailed(
        fromState,
        event,
        'Transisi dibatalkan oleh beforeTransition callback',
      );
      return false;
    }

    // Lakukan transisi
    _currentState = toState;

    // Call after transition
    await actions?.onAfterTransition(fromState, toState, event);

    return true;
  }
}
