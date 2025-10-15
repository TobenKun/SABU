# One-Touch Savings (원터치 저축) 🇰🇷

한국어 일터치 저축 앱 - 간편하게 저축하고 목표를 달성하세요!

## 주요 기능

- 🎯 **간편한 저축**: 원터치로 빠른 저축
- 📊 **진행상황 추적**: 실시간 저축 현황 및 통계
- 🏆 **마일스톤 달성**: 목표 달성 시 축하 애니메이션
- 💾 **데이터 지속성**: SQLite 데이터베이스로 안전한 데이터 저장
- ⚡ **성능 모니터링**: 60fps 유지 및 성능 최적화

## 개발 및 테스트

### 테스트 실행

```bash
# 기본 테스트 (간결한 출력)
flutter test

# 상세 로그 포함 테스트 
FLUTTER_VERBOSE_LOGS=true flutter test

# 특정 테스트만 실행
flutter test test/unit_test/korean_number_formatter_test.dart

# 커버리지 포함 테스트
flutter test --coverage
```

### 로그 제어

앱은 기본적으로 **WARNING과 ERROR만** 표시합니다. 상세한 DEBUG/INFO 로그가 필요한 경우:

**방법 1: 환경변수 사용**
```bash
FLUTTER_VERBOSE_LOGS=true flutter run
FLUTTER_VERBOSE_LOGS=true flutter test
```

**방법 2: 코드에서 직접 제어**
```dart
import 'package:one_touch_savings/services/logger_service.dart';

// 상세 로그 활성화
LoggerService.enableVerboseLogging();

// 상세 로그 비활성화 (기본값)
LoggerService.disableVerboseLogging();
```

### 성능 모니터링

앱에는 실시간 성능 모니터링이 내장되어 있습니다:
- 🎯 **타겟**: 60fps (16ms/프레임)
- 📊 **데이터베이스**: 50ms 제한
- 💾 **메모리**: 100MB 제한
- ⚠️ 성능 이슈 발생 시 자동 로깅

## 프로젝트 구조

```
lib/
├── models/          # 데이터 모델 (SavingsResult, UserProgress 등)
├── screens/         # 화면 위젯 (HomeScreen)
├── services/        # 비즈니스 로직 (DatabaseService, PerformanceService 등)
├── utils/           # 유틸리티 (KoreanNumberFormatter)
├── widgets/         # UI 컴포넌트 (SavingsButton, ProgressDisplay 등)
└── main.dart        # 앱 진입점

test/
├── unit_test/       # 유닛 테스트
├── widget_test/     # 위젯 테스트
├── integration_test/ # 통합 테스트
└── widget_test.dart # 기본 위젯 테스트
```

## 기술 스택

- **Flutter 3.16+** / **Dart 3.0+**
- **SQLite** (sqflite) - 로컬 데이터 저장
- **Material 3** - 모던 UI 디자인
- **성능 모니터링** - 맞춤형 성능 추적 시스템

## 개발 가이드라인

- 📝 **80%+ 테스트 커버리지** 유지
- 🎯 **60fps 성능** 목표
- 🇰🇷 **한국어 UI/UX** 최적화
- 📱 **Material Design 3** 준수

---

Flutter 개발 도움말:
- [Flutter 시작하기](https://docs.flutter.dev/get-started/codelab)
- [Flutter 쿡북](https://docs.flutter.dev/cookbook)
