//
//  GRColor.swift
//  Grruung
//
//  Created by NoelMacMini on 5/1/25.
//
import SwiftUI

// 색상 정보 구조체
struct GRColorInfo: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let color: Color
    let hex: String
    
    // Hashable 프로토콜 구현
    func hash(into hasher: inout Hasher) {
        hasher.combine(hex)
    }
    
    static func == (lhs: GRColorInfo, rhs: GRColorInfo) -> Bool {
        lhs.hex == rhs.hex
    }
}

// MARK: - 구르릉 색상 관리
// 코드 사용 예시
// .background(GRColor.pointColor)
// .foregroundColor(GRColor.pointColor)
// .foregroundStyle(GRColor.pointColor)
// .tint(GRColor.pointColor)

struct GRColor {
    // 색상 테마1 (예시)
    static let mainColor = Color(hex: "055A7F")
    static let subColorOne = Color(hex: "B1926F")
    static let subColorTwo = Color(hex: "BAA78E")
    static let pointColor = Color(hex: "0C96D1")
    static let lightColor = Color(hex: "F1F2F2")
    
    // 색상 테마2 (예시)
//    static let mainColor = Color(hex: "E74C3C")
//    static let subColorOne = Color(hex: "E67E22")
//    static let subColorTwo = Color(hex: "F1C40F")
//    static let pointColor = Color(hex: "3498DB")
//    static let lightColor = Color(hex: "F1F2F2")

    // 폰트 색상1 (예시)
    static let fontMainColor = Color(hex: "323439")
    static let fontSubColor = Color(hex: "4E515A")
    
    // 개별 색상
    static let grColorRed = Color(hex: "E74C3C")
    static let grColorOrange = Color(hex: "E67E22")
    static let grColorYellow = Color(hex: "F1C40F")
    static let grColorGreen = Color(hex: "2ECC71")
    static let grColorBlue = Color(hex: "3498DB")
    static let grColorPurple = Color(hex: "9B59B6")
    static let grColorBrown = Color(hex: "8B4513")
    static let grColorGray = Color(hex: "95A5A6")
    static let grColorOcean = Color(hex: "55b4d4")
    
    // Gray Scale
    static let gray50Background = Color(hex: "F6F7F8")
    static let gray200Line = Color(hex: "DBDEE2")
    static let gray300Disable = Color(hex: "C9CED3")
    static let gray400 = Color(hex: "A5ACB5")
    static let gray500 = Color(hex: "7E8592")
    static let gray600 = Color(hex: "717784")
    static let gray700 = Color(hex: "5F626E")
    static let gray800 = Color(hex: "4E515A")
    static let gray900 = Color(hex: "323439")
    
    // Utility Colors
    static let redError = Color(hex: "EB003B")
}





// MARK: - Color Methods (hex코드를 이용하기 위한 extension)
extension UIColor {
    convenience init(hex: String) {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")
        
        var rgb: UInt64 = 0
        Scanner(string: hexSanitized).scanHexInt64(&rgb)
        
        let red = CGFloat((rgb & 0xFF0000) >> 16) / 255.0
        let green = CGFloat((rgb & 0x00FF00) >> 8) / 255.0
        let blue = CGFloat(rgb & 0x0000FF) / 255.0
        
        self.init(red: red, green: green, blue: blue, alpha: 1.0)
    }
}
extension Color {
    init(hex: String) {
        let uiColor = UIColor(hex: hex)
        self.init(uiColor)
    }
    
    // 이 메서드는 기존 코드에 있었지만, Int 기반 hex 생성자도 유지
    init(hex: Int, alpha: Double = 1.0) {
        let red = Double((hex >> 16) & 0xFF) / 255.0
        let green = Double((hex >> 8) & 0xFF) / 255.0
        let blue = Double(hex & 0xFF) / 255.0
        self.init(.sRGB, red: red, green: green, blue: blue, opacity: alpha)
    }
    
    // hex 문자열을 가져오는 helper (Firebase에 저장하는 용도)
    func toHex() -> String? {
        guard let components = UIColor(self).cgColor.components else { return nil }
        
        let r = Float(components[0])
        let g = Float(components[1])
        let b = Float(components[2])
        
        return String(format: "%02lX%02lX%02lX",
                      lroundf(r * 255),
                      lroundf(g * 255),
                      lroundf(b * 255))
    }
}

