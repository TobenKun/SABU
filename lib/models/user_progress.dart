import 'dart:convert';

class UserProgress {
  final int totalSavings;
  final int totalSessions;
  final int todaySessionCount;
  final DateTime lastSaveDate;
  final int currentStreak;
  final int longestStreak;
  final List<int> milestones;
  
  UserProgress({
    required this.totalSavings,
    required this.totalSessions,
    required this.todaySessionCount,
    required this.lastSaveDate,
    required this.currentStreak,
    required this.longestStreak,
    required this.milestones,
  });
  
  factory UserProgress.empty() {
    return UserProgress(
      totalSavings: 0,
      totalSessions: 0,
      todaySessionCount: 0,
      lastSaveDate: DateTime.now(),
      currentStreak: 0,
      longestStreak: 0,
      milestones: [],
    );
  }
  
  factory UserProgress.fromMap(Map<String, dynamic> map) {
    return UserProgress(
      totalSavings: map['total_savings'] as int,
      totalSessions: map['total_sessions'] as int,
      todaySessionCount: map['today_session_count'] as int,
      lastSaveDate: DateTime.fromMillisecondsSinceEpoch(map['last_save_date'] as int),
      currentStreak: map['current_streak'] as int,
      longestStreak: map['longest_streak'] as int,
      milestones: (jsonDecode(map['milestones'] as String) as List<dynamic>)
          .map((e) => e as int)
          .toList(),
    );
  }
  
  Map<String, dynamic> toMap() {
    return {
      'id': 1,
      'total_savings': totalSavings,
      'total_sessions': totalSessions,
      'today_session_count': todaySessionCount,
      'last_save_date': lastSaveDate.millisecondsSinceEpoch,
      'current_streak': currentStreak,
      'longest_streak': longestStreak,
      'milestones': jsonEncode(milestones),
    };
  }
  
  UserProgress copyWith({
    int? totalSavings,
    int? totalSessions,
    int? todaySessionCount,
    DateTime? lastSaveDate,
    int? currentStreak,
    int? longestStreak,
    List<int>? milestones,
  }) {
    return UserProgress(
      totalSavings: totalSavings ?? this.totalSavings,
      totalSessions: totalSessions ?? this.totalSessions,
      todaySessionCount: todaySessionCount ?? this.todaySessionCount,
      lastSaveDate: lastSaveDate ?? this.lastSaveDate,
      currentStreak: currentStreak ?? this.currentStreak,
      longestStreak: longestStreak ?? this.longestStreak,
      milestones: milestones ?? this.milestones,
    );
  }
  
  bool validate() {
    if (totalSavings != totalSessions * 1000) return false;
    if (todaySessionCount < 0) return false;
    if (currentStreak < 0) return false;
    if (longestStreak < currentStreak) return false;
    return milestones.every((milestone) => milestone % 10000 == 0);
  }
  
  @override
  String toString() {
    return 'UserProgress{totalSavings: $totalSavings, totalSessions: $totalSessions, todaySessionCount: $todaySessionCount, lastSaveDate: $lastSaveDate, currentStreak: $currentStreak, longestStreak: $longestStreak, milestones: $milestones}';
  }
  
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserProgress &&
        other.totalSavings == totalSavings &&
        other.totalSessions == totalSessions &&
        other.todaySessionCount == todaySessionCount &&
        other.lastSaveDate == lastSaveDate &&
        other.currentStreak == currentStreak &&
        other.longestStreak == longestStreak &&
        _listEquals(other.milestones, milestones);
  }
  
  @override
  int get hashCode {
    return totalSavings.hashCode ^
        totalSessions.hashCode ^
        todaySessionCount.hashCode ^
        lastSaveDate.hashCode ^
        currentStreak.hashCode ^
        longestStreak.hashCode ^
        milestones.hashCode;
  }
  
  bool _listEquals<T>(List<T> a, List<T> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}