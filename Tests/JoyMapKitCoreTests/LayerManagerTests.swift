import XCTest
@testable import JoyMapKitCore

final class LayerManagerTests: XCTestCase {
    var manager: LayerManager!

    override func setUp() {
        super.setUp()
        manager = LayerManager()
    }

    // MARK: - Initial state

    func testInitiallyNoLayersActive() {
        XCTAssertFalse(manager.isActive("combat"))
        XCTAssertFalse(manager.isActive("menu"))
        XCTAssertFalse(manager.isActive(""))
    }

    // MARK: - Activate / Deactivate

    func testActivateMakesLayerActive() {
        manager.activate("combat")

        XCTAssertTrue(manager.isActive("combat"))
    }

    func testDeactivateMakesLayerInactive() {
        manager.activate("combat")
        manager.deactivate("combat")

        XCTAssertFalse(manager.isActive("combat"))
    }

    func testDeactivateNonActiveLayerIsNoOp() {
        // Should not crash or error
        manager.deactivate("nonexistent")

        XCTAssertFalse(manager.isActive("nonexistent"))
    }

    func testActivateMultipleLayers() {
        manager.activate("combat")
        manager.activate("menu")

        XCTAssertTrue(manager.isActive("combat"))
        XCTAssertTrue(manager.isActive("menu"))
    }

    func testDeactivateOnlyAffectsTargetLayer() {
        manager.activate("combat")
        manager.activate("menu")

        manager.deactivate("combat")

        XCTAssertFalse(manager.isActive("combat"))
        XCTAssertTrue(manager.isActive("menu"))
    }

    // MARK: - Toggle

    func testToggleActivatesInactiveLayer() {
        manager.toggle("combat")

        XCTAssertTrue(manager.isActive("combat"))
    }

    func testToggleDeactivatesActiveLayer() {
        manager.activate("combat")

        manager.toggle("combat")

        XCTAssertFalse(manager.isActive("combat"))
    }

    func testDoubleToggleRestoresState() {
        manager.toggle("combat")
        manager.toggle("combat")

        XCTAssertFalse(manager.isActive("combat"))
    }

    // MARK: - DeactivateAll

    func testDeactivateAllClearsEverything() {
        manager.activate("combat")
        manager.activate("menu")
        manager.activate("stealth")

        manager.deactivateAll()

        XCTAssertFalse(manager.isActive("combat"))
        XCTAssertFalse(manager.isActive("menu"))
        XCTAssertFalse(manager.isActive("stealth"))
    }

    func testDeactivateAllOnEmptyIsNoOp() {
        manager.deactivateAll()

        XCTAssertFalse(manager.isActive("combat"))
    }

    // MARK: - Duplicate activation

    func testActivatingSameLayerTwiceIsIdempotent() {
        manager.activate("combat")
        manager.activate("combat")

        XCTAssertTrue(manager.isActive("combat"))

        // Single deactivate should be sufficient
        manager.deactivate("combat")
        XCTAssertFalse(manager.isActive("combat"))
    }
}
