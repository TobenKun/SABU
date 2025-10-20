import 'package:flutter/material.dart';
import '../models/design_version_setting.dart';
import '../services/design_version_service.dart';
import '../widgets/design_version_toggle.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final DesignVersionService _designVersionService = DesignVersionService();
  DesignVersion? _currentVersion;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCurrentVersion();
  }

  Future<void> _loadCurrentVersion() async {
    try {
      final version = await _designVersionService.getCurrentDesignVersion();
      if (mounted) {
        setState(() {
          _currentVersion = version;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _currentVersion = DesignVersion.v1;
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _onVersionChanged(DesignVersion newVersion) async {
    try {
      await _designVersionService.setDesignVersion(newVersion);
      if (mounted) {
        setState(() {
          _currentVersion = newVersion;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('인터페이스 버전이 변경되었습니다'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('설정 저장에 실패했습니다'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('설정'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_currentVersion != null)
                    DesignVersionToggle(
                      currentVersion: _currentVersion!,
                      onVersionChanged: _onVersionChanged,
                    ),
                ],
              ),
            ),
    );
  }
}