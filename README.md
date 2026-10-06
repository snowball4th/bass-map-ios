# BassMap Prototype

아이폰 사진 앱의 `Bass` 앨범에서 GPS가 들어 있는 사진을 읽어 지도에 표시하는 iOS 프로토타입입니다.

## Prototype scope

- 사진 보관함 읽기 권한 요청
- 이름이 `Bass`인 사용자 앨범 탐색
- 앨범 내 이미지 중 GPS 위치가 있는 사진만 로드
- MapKit 지도에 사진 썸네일 핀 표시
- 핀 탭 시 사진 / 촬영 날짜 / 위도·경도 표시
- 서버 없음
- 별도 위치 권한 없음 (사진에 이미 저장된 위치 메타데이터만 사용)

## Requirements

- macOS
- Xcode 16 이상 권장
- iOS 17 이상
- 실제 iPhone 권장

## Xcode에서 실행하기

1. Xcode → Create New Project
2. iOS → App
3. Product Name: `BassMap`
4. Interface: SwiftUI
5. Language: Swift
6. Deployment Target: iOS 17.0 이상
7. 자동 생성된 `ContentView.swift` 삭제
8. 이 저장소의 `BassMap/` 아래 Swift 파일들을 프로젝트에 추가
9. Target → Info → Custom iOS Target Properties에 `Privacy - Photo Library Usage Description` 추가
10. 값: `Bass 앨범의 낚시 사진과 촬영 위치를 지도에 표시하기 위해 사진 보관함 접근이 필요합니다.`
11. iPhone Photos 앱에 `Bass`라는 앨범을 만들고 GPS가 있는 사진을 넣은 뒤 앱 실행

> 현재 버전은 Photos 앱의 "폴더"가 아니라 이름이 Bass인 "앨범"을 찾습니다.
