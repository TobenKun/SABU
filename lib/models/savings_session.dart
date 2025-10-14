class SavingsSession {
  final int id;
  final int amount;
  final DateTime timestamp;
  final String? notes;
  
  SavingsSession({
    required this.id,
    required this.amount,
    required this.timestamp,
    this.notes,
  });
  
  factory SavingsSession.fromMap(Map<String, dynamic> map) {
    return SavingsSession(
      id: map['id'] as int,
      amount: map['amount'] as int,
      timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp'] as int),
      notes: map['notes'] as String?,
    );
  }
  
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'amount': amount,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'notes': notes,
    };
  }
  
  SavingsSession copyWith({
    int? id,
    int? amount,
    DateTime? timestamp,
    String? notes,
  }) {
    return SavingsSession(
      id: id ?? this.id,
      amount: amount ?? this.amount,
      timestamp: timestamp ?? this.timestamp,
      notes: notes ?? this.notes,
    );
  }
  
  bool validate() {
    return amount == 1000;
  }
  
  @override
  String toString() {
    return 'SavingsSession{id: $id, amount: $amount, timestamp: $timestamp, notes: $notes}';
  }
  
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SavingsSession &&
        other.id == id &&
        other.amount == amount &&
        other.timestamp == timestamp &&
        other.notes == notes;
  }
  
  @override
  int get hashCode {
    return id.hashCode ^
        amount.hashCode ^
        timestamp.hashCode ^
        notes.hashCode;
  }
}