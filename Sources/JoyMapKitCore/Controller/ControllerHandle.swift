import Foundation
import GameController

/// Stable identity wrapper around GCController.
/// GCController objects can be recreated on reconnect; this provides stable tracking.
public final class ControllerHandle: Identifiable, Hashable {
    public let id: UUID
    public let vendorName: String
    public let productCategory: String
    public let controllerType: ControllerType

    public private(set) weak var controller: GCController?
    public private(set) var availableElements: [String]

    public init(controller: GCController) {
        self.id = UUID()
        self.vendorName = controller.vendorName ?? "Unknown"
        self.productCategory = controller.productCategory
        self.controller = controller

        // Determine controller type from profile
        if controller.extendedGamepad is GCXboxGamepad {
            self.controllerType = .xbox
        } else if controller.extendedGamepad is GCDualSenseGamepad {
            self.controllerType = .dualSense
        } else if controller.extendedGamepad is GCDualShockGamepad {
            self.controllerType = .dualShock
        } else {
            self.controllerType = .generic
        }

        // Discover all available input elements dynamically
        // Use .elements (dictionary [String: GCControllerElement]), not .allElements (Set)
        self.availableElements = Array(controller.physicalInputProfile.elements.keys).sorted()
    }

    /// Rebind to a new GCController instance (e.g., after reconnect).
    public func rebind(to controller: GCController) {
        self.controller = controller
        self.availableElements = Array(controller.physicalInputProfile.elements.keys).sorted()
    }

    // MARK: - Hashable

    public static func == (lhs: ControllerHandle, rhs: ControllerHandle) -> Bool {
        lhs.id == rhs.id
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
