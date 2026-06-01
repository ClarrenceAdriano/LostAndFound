//
//  AppColors.swift
//  LostAndFound
//
//  Created by Dylan on 01/06/26.
//
import SwiftUI

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

extension Date {
    func formatted(as format: String = "dd MMM yyyy") -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = format
        return formatter.string(from: self)
    }
}


extension String {

    var isValidUCEmail: Bool {
        contains("@") && hasSuffix("@ciputra.ac.id")
    }

    func meetsMinLength(_ min: Int) -> Bool {
        count >= min
    }

    var isNotBlank: Bool {
        !trimmingCharacters(in: .whitespaces).isEmpty
    }
}


enum AppColors {

    static let primary   = Color(hex: "1B6B5A")
    static let lost      = Color(hex: "E8820A")
    static let found     = Color(hex: "1D9E75")
    static let admin     = Color(hex: "5A72B5")

    static let background = Color(UIColor.systemBackground)
    static let secondary  = Color(UIColor.secondarySystemBackground)
    static let card       = Color(UIColor.systemBackground)

    static let textPrimary   = Color(UIColor.label)
    static let textSecondary = Color(UIColor.secondaryLabel)

    static let separator = Color(UIColor.systemGray5)
}

