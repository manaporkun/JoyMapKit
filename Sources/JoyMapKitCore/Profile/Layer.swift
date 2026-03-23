import Foundation

/// Manages runtime layer activation state. When a layer is active, its bindings
/// take priority over the base profile bindings. LayerConfig is defined in Profile.swift.
public final class LayerManager {
    private var activeLayers: Set<String> = []
    private var activationOrder: [String] = []

    public init() {}

    public func isActive(_ layerName: String) -> Bool {
        activeLayers.contains(layerName)
    }

    public func activate(_ layerName: String) {
        activeLayers.insert(layerName)
        activationOrder.removeAll { $0 == layerName }
        activationOrder.append(layerName)
    }

    public func deactivate(_ layerName: String) {
        activeLayers.remove(layerName)
        activationOrder.removeAll { $0 == layerName }
    }

    public func toggle(_ layerName: String) {
        if activeLayers.contains(layerName) {
            activeLayers.remove(layerName)
            activationOrder.removeAll { $0 == layerName }
        } else {
            activeLayers.insert(layerName)
            activationOrder.append(layerName)
        }
    }

    public var activeLayersInPriorityOrder: [String] {
        activationOrder.reversed()
    }

    public func deactivateAll() {
        activeLayers.removeAll()
        activationOrder.removeAll()
    }
}
