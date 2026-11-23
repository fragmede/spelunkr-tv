import SpelunkrCore
import SwiftUI

struct AudioCreditView: View {
    let audio: AudioPlayback

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Label("\(audio.title) — \(audio.artist)", systemImage: "music.note")
            if let license = audio.license {
                Text(license)
            }
        }
        .font(.caption)
        .foregroundStyle(.secondary)
        .accessibilityElement(children: .combine)
    }
}
