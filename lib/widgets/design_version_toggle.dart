import 'package:flutter/material.dart';
import '../models/design_version_setting.dart';

/// Widget that provides radio button selection between V1 and V2 design versions
class DesignVersionToggle extends StatelessWidget {
  final DesignVersion currentVersion;
  final ValueChanged<DesignVersion> onVersionChanged;

  const DesignVersionToggle({
    super.key,
    required this.currentVersion,
    required this.onVersionChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '인터페이스 버전',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            // ignore: deprecated_member_use
            RadioListTile<DesignVersion>(
              title: const Text('V1 - 전체 기능'),
              subtitle: const Text('모든 차트와 통계 표시'),
              value: DesignVersion.v1,
              // ignore: deprecated_member_use
              groupValue: currentVersion,
              // ignore: deprecated_member_use
              onChanged: (value) {
                if (value != null) {
                  onVersionChanged(value);
                }
              },
            ),
            // ignore: deprecated_member_use
            RadioListTile<DesignVersion>(
              title: const Text('V2 - 간단한 화면'),
              subtitle: const Text('필수 기능만 + 귀여운 거북이'),
              value: DesignVersion.v2,
              // ignore: deprecated_member_use
              groupValue: currentVersion,
              // ignore: deprecated_member_use
              onChanged: (value) {
                if (value != null) {
                  onVersionChanged(value);
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}