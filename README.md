# JoyMapKit

A macOS gamepad-to-keyboard/mouse mapper. Connect any MFi, Xbox, DualSense, DualShock, or Nintendo Pro controller and remap its inputs to keyboard shortcuts, mouse movement, scrolling, macros, and shell commands.

Swift Package. Requires macOS 13+.

## Features

- Map gamepad buttons to keyboard shortcuts with modifier support (command, option, control, shift, fn)
- Mouse cursor control via analog sticks with configurable sensitivity
- Scroll emulation with adjustable speed
- Analog stick response curves: linear, quadratic, cubic, sCurve, and custom point-based curves
- Inner and outer deadzone configuration per stick
- Stick modes: mouse, scroll, WASD, arrows, or disabled
- Trigger modes: digital (threshold-based), analog, mouseScroll, or disabled
- Chord detection -- bind actions to simultaneous button presses with configurable time window
- Sequence detection -- bind actions to button sequences within a timeout
- Hold behaviors: onPress, onRelease, whileHeld (with repeat interval), and toggle
- Layers -- hold a button to activate an overlay binding set
- Macros -- multi-step action sequences with per-step delay and hold duration
- Shell command execution from any button
- Profile switching and layer toggling as bindable actions
- JSON-based profile system with per-app auto-switching on frontmost application change
- Per-controller-type profile matching (Xbox, DualSense, DualShock, Nintendo Pro, generic)
- CLI tool for headless operation
- SwiftUI menu bar app with profile editor, "press to assign" input capture, and response curve visualizer
- Requires macOS Accessibility permission for keyboard/mouse simulation

## Installation

### Homebrew

```
brew install manaporkun/tap/joymapkit
```

### Build from Source

```
git clone https://github.com/manaporkun/JoyMapKit.git
cd JoyMapKit
swift build -c release
```

The built binary is at `.build/release/joymapkit`.

## Quick Start

1. Grant Accessibility permission to your terminal (System Settings > Privacy & Security > Accessibility).
2. Connect a gamepad.
3. Run the service:

```
joymapkit run
```

JoyMapKit loads profiles from `~/.config/joymapkit/profiles/`. On first run, if no profiles exist, the built-in default profile maps common desktop navigation: A = Return, B = Escape, right stick = mouse, left stick = scroll, triggers = mouse clicks.

Use `joymapkit test` to see live input from your controller and identify element names for your bindings.

## Configuration

Profiles are JSON files stored in `~/.config/joymapkit/profiles/`. Each profile defines button bindings, stick behavior, trigger behavior, and optional layers.

### Profile Structure

```json
{
  "id": "00000000-0000-0000-0000-000000000001",
  "name": "my-profile",
  "version": 1,
  "metadata": {
    "author": "Your Name",
    "description": "Profile description"
  },
  "appBundleIDs": ["com.apple.Safari", "com.google.Chrome"],
  "controllerTypes": ["xbox", "dualSense"],
  "bindings": [],
  "layers": [],
  "sticks": {},
  "triggers": {}
}
```

Set `appBundleIDs` to `["*"]` to match all applications. When multiple profiles match, the most specific one (by app bundle ID) wins. The `controllerTypes` field is optional and accepts `xbox`, `dualSense`, `dualShock`, `nintendoPro`, and `generic`.

### Bindings

Each binding connects an input to an action:

```json
{
  "input": { "type": "single", "element": "Button A" },
  "action": { "type": "keyPress", "keyCode": 36, "modifiers": ["command"], "key": "Cmd+Return" },
  "holdBehavior": { "type": "onPress" }
}
```

**Input types:**

| Type | Fields | Description |
|------|--------|-------------|
| `single` | `element` | Single button press |
| `chord` | `elements` | Simultaneous buttons (e.g., `["Button A", "Button B"]`) |
| `sequence` | `elements`, `timeoutMs` | Ordered button sequence within timeout |

**Action types:**

| Type | Fields | Description |
|------|--------|-------------|
| `keyPress` | `keyCode`, `modifiers`, `key` | Simulate a keyboard shortcut |
| `mouseClick` | `button` (`left`, `right`, `middle`) | Simulate a mouse click |
| `mouseMove` | `dx`, `dy` | Move the cursor by a delta |
| `scroll` | `dx`, `dy` | Scroll by a delta |
| `shell` | `command`, `arguments` | Run a shell command |
| `macro` | `steps`, `repeatCount`, `name` | Execute a multi-step macro |
| `profileSwitch` | `profileName` | Switch to another profile |
| `layerToggle` | `layerName` | Toggle a layer on/off |

**Hold behaviors:** `onPress` (default), `onRelease`, `whileHeld` (requires `repeatIntervalMs`), `toggle`.

### Sticks

```json
"sticks": {
  "Right Thumbstick": {
    "mode": "mouse",
    "deadzone": 0.10,
    "outerDeadzone": 0.95,
    "responseCurve": { "type": "quadratic" },
    "sensitivity": 1.5
  },
  "Left Thumbstick": {
    "mode": "scroll",
    "deadzone": 0.15,
    "outerDeadzone": 0.95,
    "responseCurve": { "type": "linear" },
    "sensitivity": 1.0,
    "scrollSpeed": 5.0
  }
}
```

Stick modes: `mouse`, `scroll`, `wasd`, `arrows`, `disabled`. Response curve types: `linear`, `quadratic`, `cubic`, `sCurve`, `custom`. For custom curves, provide a `customPoints` array of `[x, y]` pairs.

### Triggers

```json
"triggers": {
  "Right Trigger": {
    "mode": "digital",
    "threshold": 0.3,
    "action": { "type": "mouseClick", "button": "left" }
  }
}
```

Trigger modes: `digital`, `analog`, `mouseScroll`, `disabled`.

### Layers

Layers let you define alternate bindings activated by holding a button:

```json
"layers": [
  {
    "name": "modifier",
    "activator": { "type": "single", "element": "Left Shoulder" },
    "bindings": [
      {
        "input": { "type": "single", "element": "Button A" },
        "action": { "type": "keyPress", "keyCode": 6, "modifiers": ["command"], "key": "Cmd+Z" }
      }
    ]
  }
]
```

When the activator is held, the layer's bindings override matching base bindings.

## CLI Usage

```
joymapkit run [--profile <name>] [--no-auto-switch] [--config-dir <path>]
```

Start the mapping service. Optionally lock to a specific profile or disable automatic profile switching on app focus change.

```
joymapkit test [--raw]
```

Live input monitor. Displays all controller events in real-time with visual bars. Use `--raw` to show unfiltered analog values.

```
joymapkit list controllers [--json]
```

List connected controllers with vendor name, category, type, and element count.

```
joymapkit list profiles [--config-dir <path>]
```

List all saved profiles with their app associations, binding counts, and descriptions.

## License

MIT. See [LICENSE](LICENSE) for details.
