# One-Touch Savings (원터치 저축) 🇰🇷

한국어 일터치 저축 앱 - 간편하게 저축하고 목표를 달성하세요!

## 주요 기능

### 🎨 **듀얼 디자인 시스템**
- **V1 (클래식)**: 풍부한 진행률 표시, 마일스톤 축하, 상세 통계
- **V2 (심플)**: 핵심 기능만 집중, 애니메이션 캐릭터로 시각적 피드백

### ⚡ **핵심 기능**
- 🎯 **간편한 저축**: 원터치로 빠른 저축 (₩1,000 단위)
- 📊 **진행상황 추적**: 실시간 저축 현황 및 통계
- 🐢 **애니메이션 캐릭터**: 저축 활동에 반응하는 움직이는 거북이
- 🏆 **마일스톤 달성**: 목표 달성 시 축하 애니메이션
- 💾 **데이터 지속성**: SQLite 데이터베이스로 안전한 데이터 저장
- ⚡ **성능 최적화**: 60fps 유지 및 <200ms 응답시간

## 개발 및 테스트

### 테스트 실행

```bash
# 기본 테스트 (간결한 출력)
flutter test

# 상세 로그 포함 테스트 
FLUTTER_VERBOSE_LOGS=true flutter test

# 특정 테스트만 실행
flutter test test/unit_test/korean_number_formatter_test.dart
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
├── models/          # 데이터 모델
│   ├── animation_state.dart      # 애니메이션 상태 관리
│   ├── design_version_setting.dart # V1/V2 버전 설정
│   ├── savings_result.dart       # 저축 결과 모델
│   ├── savings_session.dart      # 저축 세션 모델
│   └── user_progress.dart        # 사용자 진행 상황
├── screens/         # 화면 위젯
│   ├── home_screen.dart          # V1 메인 화면
│   ├── home_screen_v2.dart       # V2 심플 화면
│   └── settings_screen.dart      # 설정 화면
├── services/        # 비즈니스 로직
│   ├── animation_service.dart    # 애니메이션 타이머 관리
│   ├── database_service.dart     # SQLite 데이터 관리
│   ├── design_version_service.dart # 디자인 버전 관리
│   ├── feedback_service.dart     # 햅틱 피드백
│   ├── logger_service.dart       # 로깅 시스템
│   └── performance_service.dart  # 성능 모니터링
├── utils/           # 유틸리티
│   └── korean_number_formatter.dart # 한국어 숫자 포맷팅
├── widgets/         # UI 컴포넌트
│   ├── animated_character.dart   # 애니메이션 거북이 캐릭터
│   ├── design_version_toggle.dart # V1/V2 전환 토글
│   ├── milestone_celebration.dart # 마일스톤 축하 애니메이션
│   ├── progress_display.dart     # V1 진행률 표시
│   ├── savings_button.dart       # 저축 버튼
│   ├── simplified_progress_display.dart # V2 심플 진행률
│   └── usage_stats_card.dart     # 사용 통계 카드
└── main.dart        # 앱 진입점

test/
├── unit_test/       # 유닛 테스트 (23개 파일)
├── widget_test/     # 위젯 테스트 (8개 파일)
├── integration_test/ # 통합 테스트 (4개 파일)
└── widget_test.dart # 기본 위젯 테스트
```

## 현재 구현 상태

### ✅ **완료된 기능**
- **듀얼 디자인 시스템**: V1(풍부한 UI) + V2(심플한 UI) 완전 구현
- **애니메이션 캐릭터**: 5단계 거북이 애니메이션 (idle → 느린걸음 → 빠른걸음 → 느린뛰기 → 빠른뛰기)
- **데이터 지속성**: SQLite 기반 완전한 데이터 저장 및 복구
- **성능 최적화**: RepaintBoundary, 스프라이트 프리로딩, 메모리 관리
- **포괄적 테스트**: 74.8% 커버리지, 58+ 테스트 케이스
- **한국어 지원**: 완전한 한국어 UI 및 숫자 포맷팅

### 📊 **성능 지표**
- **응답 시간**: <200ms (버튼 탭 응답)
- **프레임률**: 60fps 유지 (애니메이션 중)
- **메모리 사용**: 최적화된 타이머/컨트롤러 관리
- **테스트 커버리지**: 70%+ (1,369/1,831 라인)
- **코드 품질**: 4,879 라인, 23개 소스 파일, 24개 테스트 파일

## 기술 스택

- **Flutter 3.16+** / **Dart 3.0+** - 크로스 플랫폼 모바일 앱 개발
- **SQLite (sqflite)** - 로컬 데이터 저장 및 지속성
- **SharedPreferences** - 사용자 설정 및 상태 저장
- **Material 3** - 모던 UI 디자인 시스템
- **Custom Performance Monitoring** - 실시간 성능 추적
- **sqflite_common_ffi** - 테스트 환경 데이터베이스 모킹

## 개발 가이드라인

- 📝 **70%+ 테스트 커버리지** 달성 (목표: 70%)
- 🎯 **60fps 성능** 목표 달성
- ⚡ **<200ms 응답시간** 목표 달성
- 🇰🇷 **한국어 UI/UX** 완전 최적화
- 📱 **Material Design 3** 완전 준수
- 🔧 **메모리 관리** - 모든 타이머/컨트롤러 적절히 dispose
- 🧪 **통합 테스트** - 실제 사용자 플로우 검증

## 프로젝트 마일스톤

### Phase 1-5: 기본 기능 구현 ✅
- SQLite 데이터베이스 설계 및 구현
- 기본 저축 기능 및 UI 컴포넌트
- 한국어 숫자 포맷팅 및 로컬라이제이션

### Phase 6: 테스트 인프라 구축 ✅
- 포괄적 테스트 스위트 구축 (58+ 테스트)
- 74.8% 코드 커버리지 달성
- 성능 테스트 및 벤치마킹

### Phase 7: V2 디자인 시스템 ✅
- 듀얼 디자인 시스템 (V1/V2) 구현
- 애니메이션 캐릭터 시스템
- 반응형 레이아웃 및 성능 최적화

### Phase 8: 성능 최적화 ✅ 
- RepaintBoundary 최적화
- 스프라이트 프리로딩
- 타이머/컨트롤러 메모리 관리
- 60fps 및 <200ms 응답시간 달성

---

Flutter 개발 도움말:
- [Flutter 시작하기](https://docs.flutter.dev/get-started/codelab)
- [Flutter 쿡북](https://docs.flutter.dev/cookbook)
