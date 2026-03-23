import Foundation

/// A modifier-activated binding overlay. When a layer's activator is held,
/// its bindings take priority over the base profile bindings.
/// Phase 4 implementation — the LayerConfig model is in Profile.swift.
/// This file will hold runtime layer state management.
public final class LayerManager {
    private var activeLayers: Set<String> = []

    public init() {}

    public func isActive(_ layerName: String) -> Bool {
        activeLayers.contains(layerName)
    }

    public func activate(_ layerName: String) {
        activeLayers.insert(layerName)
    }

    public func deactivate(_ layerName: String) {
        activeLayers.remove(layerName)
    }

    public func toggle(_ layerName: String) {
        if activeLayers.contains(layerName) {
            activeLayers.remove(layerName)
        } else {
            activeLayers.insert(layerName)
        }
    }

    public func deactivateAll() {
        activeLayers.removeAll()
    }
}
