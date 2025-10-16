import 'package:flutter/material.dart';
import '../models/user_progress.dart';

class UsageStatsCard extends StatelessWidget {
  final UserProgress progress;

  const UsageStatsCard({
    super.key,
    required this.progress,
  });

  Widget _buildStatColumn(String label, String value, IconData icon) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 24,
          color: Colors.grey[600],
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('usage_stats_card'),
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            spreadRadius: 2,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildStatColumn(
              '오늘',
              '${progress.todaySessionCount}회',
              Icons.today,
            ),
            _buildStatColumn(
              '총 저축',
              '${progress.totalSessions}회',
              Icons.savings,
            ),
            _buildStatColumn(
              '연속 기록',
              '${progress.currentStreak}일',
              Icons.local_fire_department,
            ),
          ],
        ),
      ),
    );
  }
}