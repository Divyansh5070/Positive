
import SwiftUI

// MARK: - Hardcoded Color Palette
extension Color {
    static let appBackground  = Color(red: 0.961, green: 0.941, blue: 0.910) // warm cream
    static let cardBackground = Color(red: 1.000, green: 0.997, blue: 0.992)
    static let accentYellow   = Color(red: 0.961, green: 0.784, blue: 0.259) // #F5C842
    static let userBlue       = Color(red: 0.537, green: 0.769, blue: 0.882) // #89C4E1
    static let buddyPink      = Color(red: 0.957, green: 0.643, blue: 0.643) // #F4A4A4
    static let bothGreen      = Color(red: 0.561, green: 0.839, blue: 0.580) // #8FD694
    static let easyGreen      = Color(red: 0.561, green: 0.839, blue: 0.580)
    static let mediumYellow   = Color(red: 0.961, green: 0.784, blue: 0.259)
    static let hardRed        = Color(red: 0.957, green: 0.643, blue: 0.643)
    static let textPrimary    = Color(red: 0.102, green: 0.086, blue: 0.071) // near-black
    static let sketchBorder   = Color(red: 0.102, green: 0.086, blue: 0.071)
    static let tagBackground  = Color(red: 0.941, green: 0.922, blue: 0.878)
}

// MARK: - Fonts
extension Font {
    static func sketch(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        // Use rounded system typography for better readability and consistency.
        .system(size: size, weight: weight, design: .rounded)
    }
    static func sketchBold(_ size: CGFloat) -> Font {
        .system(size: size, weight: .bold, design: .rounded)
    }
    // Keep caveat names as aliases so no other files need to change
    static func caveat(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        sketch(size, weight: weight)
    }
    static func caveatBold(_ size: CGFloat) -> Font {
        sketchBold(size)
    }
}

// MARK: - Dotted Background
struct DottedBackground: View {
    var body: some View {
        Color.appBackground
            .overlay(
                Canvas { context, size in
                    let spacing: CGFloat = 20
                    let dotSize: CGFloat = 1.8
                    var y: CGFloat = spacing / 2
                    while y < size.height {
                        var x: CGFloat = spacing / 2
                        while x < size.width {
                            let rect = CGRect(x: x - dotSize/2, y: y - dotSize/2,
                                             width: dotSize, height: dotSize)
                            context.fill(Path(ellipseIn: rect),
                                         with: .color(Color.sketchBorder.opacity(0.15)))
                            x += spacing
                        }
                        y += spacing
                    }
                }
            )
            .ignoresSafeArea()
    }
}

// MARK: - Sketch Card Modifier
struct SketchCard: ViewModifier {
    var padding: CGFloat = 16
    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(Color.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.sketchBorder, lineWidth: 2)
            )
            .shadow(color: Color.sketchBorder.opacity(0.10), radius: 4, x: 2, y: 3)
    }
}

extension View {
    func sketchCard(padding: CGFloat = 16) -> some View {
        modifier(SketchCard(padding: padding))
    }
}

// MARK: - User Avatar Badge
struct UserBadge: View {
    let user: UserIdentity
    var size: CGFloat = 34

    var body: some View {
        Text(user.initial)
            .font(.sketchBold(size * 0.55))
            .foregroundColor(.white)
            .frame(width: size, height: size)
            .background(user == .you ? Color.userBlue : Color.buddyPink)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.sketchBorder, lineWidth: 1.5)
            )
    }
}

// MARK: - Difficulty Badge
struct DifficultyBadge: View {
    let difficulty: Difficulty

    var color: Color {
        switch difficulty {
        case .easy:   return .easyGreen
        case .medium: return .mediumYellow
        case .hard:   return .hardRed
        }
    }

    var body: some View {
        Text(difficulty.rawValue)
            .font(.sketch(14, weight: .bold))
            .foregroundColor(.textPrimary)
            .padding(.horizontal, 10)
            .padding(.vertical, 3)
            .background(color)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.sketchBorder, lineWidth: 1.5)
            )
    }
}

// MARK: - Category Tag
struct CategoryTag: View {
    let category: Category

    var body: some View {
        Text(category.rawValue)
            .font(.sketch(13))
            .foregroundColor(.textPrimary)
            .padding(.horizontal, 10)
            .padding(.vertical, 3)
            .background(Color.tagBackground)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.sketchBorder, lineWidth: 1.5)
            )
    }
}

// MARK: - Sketch Button Style
struct SketchButtonStyle: ButtonStyle {
    var fillColor: Color = .accentYellow
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .background(fillColor)
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(Color.sketchBorder, lineWidth: 2)
            )
            .shadow(color: configuration.isPressed ? .clear : Color.sketchBorder.opacity(0.25),
                    radius: 0, x: 2, y: 3)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

// MARK: - TextField Modifier
struct SketchTextField: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(Color.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.sketchBorder, lineWidth: 2)
            )
    }
}

extension View {
    func sketchTextField() -> some View {
        modifier(SketchTextField())
    }
}
