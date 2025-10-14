class KoreanNumberFormatter {
  /// Format Korean Won with thousands separators
  /// Example: 1000 -> ₩1,000, 10000 -> ₩10,000
  static String formatCurrency(int amount) {
    final formatter = RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))');
    final formattedAmount = amount.toString().replaceAllMapped(
      formatter, 
      (Match match) => '${match[1]},'
    );
    return '₩$formattedAmount';
  }
  
  /// Format progress as "current / target"
  /// Example: (3000, 10000) -> "₩3,000 / ₩10,000"
  static String formatProgress(int current, int target) {
    return '${formatCurrency(current)} / ${formatCurrency(target)}';
  }
  
  /// Calculate percentage with proper clamping
  /// Returns value between 0.0 and 100.0
  static double calculatePercentage(int current, int target) {
    if (target == 0) return 0.0;
    return (current / target * 100).clamp(0.0, 100.0);
  }
  
  /// Format percentage with one decimal place
  /// Example: 33.333 -> "33.3%"
  static String formatPercentage(double percentage) {
    return '${percentage.toStringAsFixed(1)}%';
  }
  
  /// Calculate next milestone amount
  /// Returns the next 10,000 increment above current amount
  static int getNextMilestone(int currentAmount) {
    final milestoneIncrement = 10000;
    return ((currentAmount / milestoneIncrement).ceil()) * milestoneIncrement;
  }
  
  /// Get current milestone progress
  /// Returns progress towards next milestone
  static double getMilestoneProgress(int currentAmount) {
    final nextMilestone = getNextMilestone(currentAmount);
    final previousMilestone = nextMilestone - 10000;
    final progressInCurrentRange = currentAmount - previousMilestone;
    return calculatePercentage(progressInCurrentRange, 10000);
  }
  
  /// Check if amount represents a milestone
  /// Returns true if amount is exactly divisible by 10,000
  static bool isMilestone(int amount) {
    return amount > 0 && amount % 10000 == 0;
  }
  
  /// Get milestone level (1st, 2nd, 3rd, etc.)
  /// Returns 0 if not a milestone
  static int getMilestoneLevel(int amount) {
    if (!isMilestone(amount)) return 0;
    return amount ~/ 10000;
  }
  
  /// Format milestone celebration message
  /// Example: 10000 -> "첫 번째 목표 달성! ₩10,000"
  static String formatMilestoneMessage(int amount) {
    final level = getMilestoneLevel(amount);
    if (level == 0) return '';
    
    final levelText = _getOrdinalKorean(level);
    return '$levelText 목표 달성! ${formatCurrency(amount)}';
  }
  
  /// Get Korean ordinal number (1st, 2nd, 3rd, etc.)
  static String _getOrdinalKorean(int number) {
    switch (number) {
      case 1: return '첫 번째';
      case 2: return '두 번째';
      case 3: return '세 번째';
      case 4: return '네 번째';
      case 5: return '다섯 번째';
      case 6: return '여섯 번째';
      case 7: return '일곱 번째';
      case 8: return '여덟 번째';
      case 9: return '아홉 번째';
      case 10: return '열 번째';
      default: return '$number번째';
    }
  }
  
  /// Format savings session display
  /// Shows amount and timestamp in Korean format
  static String formatSavingSession(int amount, DateTime timestamp) {
    final formattedAmount = formatCurrency(amount);
    final timeString = '${timestamp.hour}:${timestamp.minute.toString().padLeft(2, '0')}';
    return '$formattedAmount (저장 시간: $timeString)';
  }
  
  /// Calculate daily/weekly/monthly averages
  static Map<String, String> calculateAverages(int totalAmount, int totalSessions, int days) {
    if (days == 0 || totalSessions == 0) {
      return {
        'daily': '₩0',
        'weekly': '₩0', 
        'monthly': '₩0',
        'perSession': '₩0',
      };
    }
    
    final dailyAverage = (totalAmount / days).round();
    final weeklyAverage = (dailyAverage * 7);
    final monthlyAverage = (dailyAverage * 30);
    final perSessionAverage = (totalAmount / totalSessions).round();
    
    return {
      'daily': formatCurrency(dailyAverage),
      'weekly': formatCurrency(weeklyAverage),
      'monthly': formatCurrency(monthlyAverage),
      'perSession': formatCurrency(perSessionAverage),
    };
  }
  
  /// Format time-based progress messages
  static String formatProgressMessage(int currentAmount, int targetAmount) {
    final percentage = calculatePercentage(currentAmount, targetAmount);
    final remaining = targetAmount - currentAmount;
    
    if (percentage >= 100) {
      return '목표 달성! 축하합니다! 🎉';
    } else if (percentage >= 90) {
      return '거의 다 왔어요! ${formatCurrency(remaining)} 남았습니다';
    } else if (percentage >= 50) {
      return '절반 이상 달성! ${formatPercentage(percentage)} 완료';
    } else if (percentage >= 25) {
      return '좋은 시작이에요! ${formatPercentage(percentage)} 완료';
    } else {
      return '화이팅! ${formatCurrency(remaining)} 남았습니다';
    }
  }
}