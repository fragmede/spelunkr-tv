import SwiftUI

struct LiveProgramProgress: View {
    let program: ProgramViewData
    @ScaledMetric(relativeTo: .caption) private var textSize = 18.0

    var body: some View {
        TimelineView(.periodic(from: .now, by: 15)) { context in
            VStack(alignment: .leading, spacing: 9) {
                HStack(spacing: 12) {
                    Label("LIVE", systemImage: "circle.fill")
                        .font(.system(size: textSize, weight: .bold, design: .monospaced))
                        .foregroundStyle(SpelunkrTheme.accent)
                    Text(program.startsAt, format: .dateTime.hour().minute())
                    Text("–")
                    Text(program.endsAt, format: .dateTime.hour().minute())
                    Spacer()
                }
                .font(.system(size: textSize, design: .monospaced))
                .foregroundStyle(SpelunkrTheme.secondary)

                ProgressView(value: program.progress(at: context.date))
                    .tint(SpelunkrTheme.accent)
                    .accessibilityLabel("Program progress")
            }
            .accessibilityElement(children: .combine)
        }
    }
}
