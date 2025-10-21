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
              title: const Text('V1 - 기본에 충실하게'),
              subtitle: const Text('응원 메시지와 목표 달성 축하 팝업이 표시됩니다.'),
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
              title: const Text('V2 - 귀여운 거북이'),
              subtitle: const Text('응원 메시지도, 축하 팝업도 없습니다.\n그래도 거북이는 귀엽죠?'),
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