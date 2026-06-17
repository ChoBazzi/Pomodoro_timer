# Pomodoro Timer

macOS용 작은 플로팅 뽀모도로 타이머입니다. 화면 오른쪽 아래에 작은 원형 타이머로 떠 있고, 마우스를 올리면 시작/정지와 세션 전환 버튼이 나타납니다.

## 주요 기능

- 집중, 짧은 휴식, 긴 휴식 세션 지원
- 작은 플로팅 타이머 창
- 창 드래그 이동 지원
- 마우스 hover 시 빠른 조작 버튼 표시
- 설정 화면에서 집중/휴식 시간과 긴 휴식 주기 변경
- 세션 전환 시 시스템 비프음과 전체화면 pulse 효과
- 흰 배경에서도 구분되는 외곽선과 둥근 모서리 UI

## 사용 방법

앱을 실행하면 작은 타이머 창이 표시됩니다.

- 타이머 중앙에 마우스를 올리면 `Start` 또는 `Stop` 버튼이 나타납니다.
- 오른쪽의 전환 버튼을 누르면 현재 세션을 건너뛰고 다음 세션으로 이동합니다.
- hover 상태에서 전환 버튼 위의 설정 버튼을 누르면 설정 화면이 열립니다.
- 설정 화면을 닫으면 다시 작은 타이머 크기로 돌아갑니다.

## 단축키

| 단축키 | 동작 |
| --- | --- |
| `Space` | 시작 / 일시정지 |
| `Command + R` | 현재 세션 리셋 |
| `Command + →` | 다음 세션으로 전환 |
| `Command + ,` | 설정 열기 / 닫기 |

## 설치

GitHub Releases에서 최신 버전의 `PomodoroTimer.zip` 또는 `PomodoroTimer.dmg`를 내려받아 실행하세요.

소스코드를 직접 빌드하지 않아도 앱을 사용할 수 있습니다.

## 개발 환경

- macOS 14 이상
- Swift 6 이상

## 개발용 실행

```sh
swift run
```

SwiftPM 캐시 권한 문제로 실행이 실패하는 환경에서는 아래처럼 프로젝트 내부 캐시를 지정할 수 있습니다.

```sh
CLANG_MODULE_CACHE_PATH="$PWD/.build/clang-module-cache" swift run --scratch-path "$PWD/.build"
```

## 직접 빌드하기

소스코드를 직접 내려받아 빌드하려면 아래 명령을 사용하세요.

```sh
swift build -c release
```

빌드된 실행 파일은 일반적으로 아래 경로에 생성됩니다.

```sh
.build/release/PomodoroTimer
```

## 배포자 참고

```sh
mkdir -p dist/PomodoroTimer.app/Contents/MacOS
cp .build/release/PomodoroTimer dist/PomodoroTimer.app/Contents/MacOS/
```

Swift Package 기반 프로젝트라 배포용 `.app`을 만들려면 앱 번들 구조와 `Info.plist`를 별도로 준비해야 합니다.

## 배포 파일

GitHub Releases에는 아래 파일을 올리는 것을 권장합니다.

- `PomodoroTimer.app`
- `PomodoroTimer.zip` 또는 `PomodoroTimer.dmg`
- 소스코드 압축 파일은 GitHub가 자동 생성

## 라이선스

이 프로젝트는 MIT License로 배포됩니다. 자세한 내용은 [LICENSE](./LICENSE)를 확인하세요.
