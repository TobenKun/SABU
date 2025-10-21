import 'package:flutter/material.dart';
import '../models/user_progress.dart';
import '../services/database_service.dart';

class UsageStatsCard extends StatefulWidget {
  final UserProgress progress;
  final bool ultraCompact;

  const UsageStatsCard({
    super.key,
    required this.progress,
    this.ultraCompact = false,
  });

  @override
  State<UsageStatsCard> createState() => _UsageStatsCardState();
}

class _UsageStatsCardState extends State<UsageStatsCard> {

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
    return FutureBuilder<int>(
      future: DatabaseService.getValidatedCurrentStreak(),
      builder: (context, snapshot) {
        final validatedStreak = snapshot.data ?? widget.progress.currentStreak;
        
        if (widget.ultraCompact) {
      // Ultra-compact version for small screens with enhanced card design
      return Container(
        key: const Key('usage_stats_card'),
        height: 100,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withValues(alpha: 0.1),
              spreadRadius: 1,
              blurRadius: 3,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.today,
                        size: 12,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 3),
                        Text(
                          '오늘',
                          style: TextStyle(
                            fontSize: 12, 
                            color: Colors.grey[700],
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                    ],
                  ),
                    Text(
                      '${widget.progress.todaySessionCount}회',
                      style: TextStyle(
                        fontSize: 12, 
                        color: Colors.grey[700],
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.savings,
                        size: 12,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 3),
                        Text(
                          '총 저축',
                          style: TextStyle(
                            fontSize: 12, 
                            color: Colors.grey[700],
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                    ],
                  ),
                    Text(
                      '${widget.progress.totalSessions}회',
                      style: TextStyle(
                        fontSize: 12, 
                        color: Colors.grey[700],
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.local_fire_department,
                        size: 12,
                        color: Colors.orange[400],
                      ),
                      const SizedBox(width: 3),
                        Text(
                          '연속 기록',
                          style: TextStyle(
                            fontSize: 12, 
                            color: Colors.grey[700],
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                    ],
                  ),
                    Text(
                      '${validatedStreak}일',
                      style: TextStyle(
                        fontSize: 12, 
                        color: Colors.grey[700],
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      );
    }

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
              '${widget.progress.todaySessionCount}회',
              Icons.today,
            ),
            _buildStatColumn(
              '총 저축',
              '${widget.progress.totalSessions}회',
              Icons.savings,
            ),
            _buildStatColumn(
              '연속 기록',
              '${validatedStreak}일',
              Icons.local_fire_department,
            ),
          ],
        ),
      ),
    );
      },
    );
  }
}