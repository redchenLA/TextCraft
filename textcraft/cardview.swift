import SwiftUI

// MARK: - Card Template
enum CardTemplate: String, CaseIterable, Identifiable {
    case gradientSunset
    case gradientOcean
    case gradientForest
    case gradientNight
    case gradientRose
    case minimalWhite
    case minimalDark
    case neonGlow
    case watercolor
    case marble
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .gradientSunset: return "日落"
        case .gradientOcean: return "海洋"
        case .gradientForest: return "森林"
        case .gradientNight: return "星空"
        case .gradientRose: return "玫瑰"
        case .minimalWhite: return "极简白"
        case .minimalDark: return "极简黑"
        case .neonGlow: return "霓虹"
        case .watercolor: return "水彩"
        case .marble: return "大理石"
        }
    }
    
    var isPremium: Bool {
        switch self {
        case .gradientSunset, .gradientOcean, .minimalWhite:
            return false
        default:
            return true
        }
    }
    
    var backgroundGradient: LinearGradient {
        switch self {
        case .gradientSunset:
            return LinearGradient(colors: [.orange, .pink, .purple], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .gradientOcean:
            return LinearGradient(colors: [.cyan, .blue, .indigo], startPoint: .top, endPoint: .bottom)
        case .gradientForest:
            return LinearGradient(colors: [.green, .teal, .mint], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .gradientNight:
            return LinearGradient(colors: [.indigo, .purple, .black], startPoint: .top, endPoint: .bottom)
        case .gradientRose:
            return LinearGradient(colors: [.pink, .rose, .red], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .minimalWhite:
            return LinearGradient(colors: [.white, Color(.systemGray6)], startPoint: .top, endPoint: .bottom)
        case .minimalDark:
            return LinearGradient(colors: [Color(.darkGray), .black], startPoint: .top, endPoint: .bottom)
        case .neonGlow:
            return LinearGradient(colors: [.purple, .cyan, .green], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .watercolor:
            return LinearGradient(colors: [Color(red: 0.7, green: 0.3, blue: 0.9).opacity(0.6),
                                            Color(red: 0.3, green: 0.7, blue: 0.9).opacity(0.6),
                                            Color(red: 0.9, green: 0.5, blue: 0.7).opacity(0.6)],
                                           startPoint: .topLeading, endPoint: .bottomTrailing)
        case .marble:
            return LinearGradient(colors: [Color(.systemGray5), Color(.systemGray4), Color(.systemGray6)],
                                   startPoint: .topLeading, endPoint: .bottomTrailing)
        }
    }
    
    var textColor: Color {
        switch self {
        case .minimalWhite, .watercolor, .marble:
            return .black
        default:
            return .white
        }
    }
    
    var shadowColor: Color {
        switch self {
        case .minimalWhite, .watercolor, .marble:
            return .black.opacity(0.1)
        default:
            return .black.opacity(0.3)
        }
    }
}

// MARK: - Card View
struct CardView: View {
    let text: String
    let template: CardTemplate
    let fontSize: CGFloat
    let showWatermark: Bool
    
    var body: some View {
        ZStack {
            // Background
            template.backgroundGradient
                .ignoresSafeArea()
            
            // Decorative elements
            decorativeElements
            
            // Text content
            VStack {
                Spacer()
                Text(text)
                    .font(.system(size: fontSize, weight: .medium, design: .serif))
                    .foregroundColor(template.textColor)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
                    .shadow(color: template.shadowColor, radius: 2, x: 1, y: 1)
                    .lineSpacing(fontSize * 0.4)
                
                Spacer()
                
                // Watermark
                if showWatermark {
                    Text("TextCraft")
                        .font(.caption2)
                        .foregroundColor(template.textColor.opacity(0.4))
                        .padding(.bottom, 24)
                }
            }
            .padding()
        }
        .cornerRadius(24)
    }
    
    private var decorativeElements: some View {
        ZStack {
            // Subtle circles for depth
            Circle()
                .fill(Color.white.opacity(0.08))
                .frame(width: 200, height: 200)
                .offset(x: -60, y: -80)
            
            Circle()
                .fill(Color.white.opacity(0.05))
                .frame(width: 150, height: 150)
                .offset(x: 80, y: 100)
            
            // Thin line decoration
            Rectangle()
                .fill(Color.white.opacity(0.15))
                .frame(width: 60, height: 1)
                .padding(.top, 40)
        }
    }
}
