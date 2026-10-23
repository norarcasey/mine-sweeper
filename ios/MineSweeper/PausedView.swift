import SwiftUI

/// Covers the board while the game is paused, so the clock is not the only
/// thing held: the board cannot be studied with the time stopped. A tap
/// anywhere on it resumes.
struct PausedView: View {
    let resume: () -> Void

    var body: some View {
        Button(action: resume) {
            VStack(spacing: 12) {
                Image(systemName: "pause.circle.fill")
                    .font(.system(size: 56))
                    .foregroundStyle(Palette.grid)
                Text("Paused")
                    .font(.title.bold())
                Text("Tap to resume")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Palette.open, in: RoundedRectangle(cornerRadius: 12))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Paused")
        .accessibilityHint("Resumes the game")
        .accessibilityIdentifier("paused")
    }
}
