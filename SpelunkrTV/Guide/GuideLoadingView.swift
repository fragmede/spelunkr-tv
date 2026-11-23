import SwiftUI

struct GuideLoadingView: View {
    let isLoading: Bool
    let errorMessage: String?
    let retry: () -> Void

    var body: some View {
        VStack(spacing: SpelunkrTheme.spacing) {
            Spacer()
            if isLoading {
                ProgressView()
                    .tint(SpelunkrTheme.accent)
                Text("Adjusting the antenna…")
                    .font(.title2)
                    .bold()
                Text("Finding the channels and what’s on now.")
                    .foregroundStyle(SpelunkrTheme.secondary)
            } else {
                ContentUnavailableView {
                    Label("The signal is out", systemImage: "antenna.radiowaves.left.and.right.slash")
                } description: {
                    Text(errorMessage ?? "The channel guide couldn’t be loaded.")
                } actions: {
                    Button("Try again", systemImage: "arrow.clockwise", action: retry)
                        .buttonStyle(GuideButtonStyle(prominent: true))
                }
            }
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
