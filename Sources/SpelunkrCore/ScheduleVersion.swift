import Foundation

public struct ScheduleVersion: Sendable {
    public let pointer: SchedulePointer
    public let manifest: Manifest
    public let platform: PlatformManifest?

    public init(pointer: SchedulePointer, manifest: Manifest, platform: PlatformManifest?) {
        self.pointer = pointer
        self.manifest = manifest
        self.platform = platform
    }
}
