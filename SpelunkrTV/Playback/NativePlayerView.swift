import AVKit
import SwiftUI

/// AVKit's tvOS transport menus aren't exposed by SwiftUI's VideoPlayer.
/// Keep this adapter limited to the system player and remote controls.
struct NativePlayerView: UIViewControllerRepresentable {
    let model: PlaybackModel
    let dismiss: () -> Void

    func makeUIViewController(context: Context) -> AVPlayerViewController {
        let controller = AVPlayerViewController()
        controller.player = model.player
        controller.appliesPreferredDisplayCriteriaAutomatically = true
        controller.requiresLinearPlayback = true
        configureMenus(controller)
        return controller
    }

    func updateUIViewController(_ controller: AVPlayerViewController, context: Context) {
        // Actions capture the stable model. Replacing menus during clock updates
        // dismisses an open menu and interrupts Siri Remote navigation.
    }

    private func configureMenus(_ controller: AVPlayerViewController) {
        let returnToLive = UIAction(title: "Return to live", image: UIImage(systemName: "dot.radiowaves.left.and.right")) { _ in
            model.goLive()
        }
        let channelGuide = UIAction(title: "Channel guide", image: UIImage(systemName: "rectangle.grid.2x2")) { _ in
            dismiss()
        }
        // AVKit otherwise offers "From Beginning" for these underlying VOD
        // files, which would leave the synchronized broadcast position.
        controller.infoViewActions = [returnToLive, channelGuide]
        controller.transportBarCustomMenuItems = [
            UIMenu(title: "Spelunkr", image: UIImage(systemName: "tv"), children: [
                UIAction(title: "Previous channel", image: UIImage(systemName: "chevron.up")) { _ in
                    model.switchChannel(-1)
                },
                UIAction(title: "Next channel", image: UIImage(systemName: "chevron.down")) { _ in
                    model.switchChannel(1)
                },
                returnToLive,
                channelGuide
            ])
        ]
    }
}
