# JoyMapKit

A macOS menu bar app that maps gamepad inputs to keyboard, mouse, and macros. Connect any MFi, Xbox, DualSense, DualShock, or Nintendo Pro controller and remap its inputs to keyboard shortcuts, mouse movement, scrolling, macros, and more.

Requires macOS 13+.

## Features

- Map gamepad buttons to keyboard shortcuts with modifier support (command, option, control, shift, fn)
- Mouse cursor control via analog sticks with configurable sensitivity
- Scroll emulation with adjustable speed
- Analog stick response curves: linear, quadratic, cubic, sCurve, and custom
- Inner and outer deadzone configuration per stick
- Stick modes: mouse, scroll, WASD, arrows, or disabled
- Trigger modes: digital (threshold-based), analog, mouseScroll, or disabled
- Chord detection -- bind actions to simultaneous button presses
- Hold behaviors: onPress, onRelease, whileHeld (auto-repeat), and toggle
- Layers -- hold a button to activate an overlay binding set
- Macros -- multi-step action sequences with delays
- Per-app auto-switching profiles based on frontmost application
- Per-controller-type profile matching (Xbox, DualSense, DualShock, Nintendo Pro)
- Built-in profile editor with "press to assign" input capture
- Response curve visualizer
- Controller test mode and rhythm game for testing inputs

## Installation

Download `JoyMapKit.zip` from the [latest release](https://github.com/manaporkun/JoyMapKit/releases/latest), unzip, and drag `JoyMapKit.app` to your Applications folder.

### Build from Source

```
git clone https://github.com/manaporkun/JoyMapKit.git
cd JoyMapKit
swift build -c release
cp -r JoyMapKit.app /Applications/
```

## Quick Start

1. Open JoyMapKit -- it runs as a menu bar app (gamepad icon).
2. Grant Accessibility permission when prompted (System Settings > Privacy & Security > Accessibility).
3. Connect a gamepad.
4. The default profile maps: A = Return, B = Escape, right stick = mouse, left stick = scroll, triggers = mouse clicks.

Use the menu bar to switch profiles, open the profile editor, or test your controller.

## Configuration

Profiles are JSON files stored in `~/.config/joymapkit/profiles/`. You can edit them in the built-in profile editor or by hand. Example profiles are included in the `Examples/profiles/` directory.

### Profile Structure

```json
{
  "name": "my-profile",
  "appBundleIDs": ["com.apple.Safari"],
  "bindings": [
    {
      "input": { "type": "single", "element": "Button A" },
      "action": { "type": "keyPress", "keyCode": 36, "modifiers": ["command"], "key": "Cmd+Return" }
    }
  ],
  "sticks": {
    "Right Thumbstick": {
      "mode": "mouse",
      "deadzone": 0.10,
      "sensitivity": 1.5,
      "responseCurve": { "type": "quadratic" }
    }
  },
  "triggers": {
    "Right Trigger": {
      "mode": "digital",
      "threshold": 0.3,
      "action": { "type": "mouseClick", "button": "left" }
    }
  },
  "layers": []
}
```

Set `appBundleIDs` to `["*"]` to match all applications. When multiple profiles match, the most specific one wins.

### Action Types

| Type | Fields | Description |
|------|--------|-------------|
| `keyPress` | `keyCode`, `modifiers`, `key` | Simulate a keyboard shortcut |
| `mouseClick` | `button` (`left`, `right`, `middle`) | Simulate a mouse click |
| `mouseMove` | `dx`, `dy` | Move the cursor by a delta |
| `scroll` | `dx`, `dy` | Scroll by a delta |
| `macro` | `steps`, `repeatCount`, `name` | Execute a multi-step macro |
| `profileSwitch` | `profileName` | Switch to another profile |
| `layerToggle` | `layerName` | Toggle a layer on/off |

### Stick Modes

`mouse`, `scroll`, `wasd`, `arrows`, `disabled`

### Hold Behaviors

`onPress` (default), `onRelease`, `whileHeld` (with `repeatIntervalMs`), `toggle`

## License

MIT. See [LICENSE](LICENSE) for details.
