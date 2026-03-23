import Foundation

/// Observable state of the JoyMapKit service.
public struct ServiceStatus: Equatable {
    public var isRunning: Bool
    public var connectedControllers: [ControllerSummary]
    public var activeProfileName: String?
    public var focusedApp: AppIdentifier?
    public var accessibilityGranted: Bool

    public init() {
        self.isRunning = false
        self.connectedControllers = []
        self.activeProfileName = nil
        self.focusedApp = nil
        self.accessibilityGranted = false
    }

    public struct ControllerSummary: Equatable, Codable, Identifiable {
        public var id: UUID
        public var name: String
        public var type: ControllerType
        public var elementCount: Int

        public init(id: UUID = UUID(), name: String, type: ControllerType, elementCount: Int) {
            self.id = id
            self.name = name
            self.type = type
            self.elementCount = elementCount
        }
    }
}
