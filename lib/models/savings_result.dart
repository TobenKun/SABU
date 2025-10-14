class SavingsResult {
  final int newTotal;
  final int todayCount;
  final List<int> milestonesHit;
  final bool success;
  final String? error;
  
  SavingsResult({
    required this.newTotal,
    required this.todayCount,
    required this.milestonesHit,
    required this.success,
    this.error,
  });
  
  factory SavingsResult.success({
    required int newTotal,
    required int todayCount,
    List<int> milestonesHit = const [],
  }) {
    return SavingsResult(
      newTotal: newTotal,
      todayCount: todayCount,
      milestonesHit: milestonesHit,
      success: true,
    );
  }
  
  factory SavingsResult.failure(String error) {
    return SavingsResult(
      newTotal: 0,
      todayCount: 0,
      milestonesHit: const [],
      success: false,
      error: error,
    );
  }
  
  @override
  String toString() {
    return 'SavingsResult{newTotal: $newTotal, todayCount: $todayCount, milestonesHit: $milestonesHit, success: $success, error: $error}';
  }
  
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SavingsResult &&
        other.newTotal == newTotal &&
        other.todayCount == todayCount &&
        _listEquals(other.milestonesHit, milestonesHit) &&
        other.success == success &&
        other.error == error;
  }
  
  @override
  int get hashCode {
    return newTotal.hashCode ^
        todayCount.hashCode ^
        milestonesHit.hashCode ^
        success.hashCode ^
        error.hashCode;
  }
  
  bool _listEquals<T>(List<T> a, List<T> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}