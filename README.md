# JoyMapKit

A macOS menu bar app that maps gamepad inputs to keyboard, mouse, and macros. Connect any MFi, Xbox, DualSense, DualShock, or Nintendo Pro controller and remap its inputs to keyboard shortcuts, mouse movement, scrolling, macros, and more.

Requires macOS 13+.

## Features

- Map gamepad buttons to keyboard shortcuts with modifier support (command, option, control, shift, fn)
- Hold modifier buttons together to combine them with other mapped key actions
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

Download **[JoyMapKit.dmg](https://github.com/manaporkun/JoyMapKit/releases/latest/download/JoyMapKit-0.2.0.dmg)**, open it, and drag JoyMapKit to Applications.

Or install from the terminal:

```
curl -sL https://github.com/manaporkun/JoyMapKit/releases/latest/download/JoyMapKit-0.2.0.dmg -o /tmp/JoyMapKit.dmg && hdiutil attach /tmp/JoyMapKit.dmg -quiet && cp -R "/Volumes/JoyMapKit/JoyMapKit.app" /Applications/ && hdiutil detach "/Volumes/JoyMapKit" -quiet && rm /tmp/JoyMapKit.dmg && open /Applications/JoyMapKit.app
```

### Build from Source

```
git clone https://github.com/manaporkun/JoyMapKit.git
cd JoyMapKit
swift build -c release
```

## Quick Start

1. Open JoyMapKit -- it runs as a menu bar app (gamepad icon).
2. Grant Accessibility permission when prompted (System Settings > Privacy & Security > Accessibility).
3. Connect a gamepad.
4. The default profile maps: A = Return, B = Escape, right stick = mouse, left stick = scroll, triggers = mouse clicks.

Use the menu bar to switch profiles, open the profile editor, or test your controller.

## Use Cases

### Coding from the Couch with Claude Code

Lean back with a controller and pair-program with Claude Code in Ghostty. JoyMapKit auto-switches to the terminal profile when Ghostty is focused.

| Controller | Action |
|---|---|
| B (Circle) | Space -- activates voice mode, talk instead of type |
| A (Cross) | Return -- accept suggestions and confirm prompts |
| D-Pad Up/Down | Arrow keys -- scroll through history and output |
| D-Pad Left/Right | Ctrl+Shift+Tab / Ctrl+Tab -- switch terminal tabs |
| Right Stick | Mouse cursor |
| Left Stick | Scroll |
| Triggers | Left/right click |
| Menu (turbo) | Hold + any button for rapid-fire repeats |

### Desktop Navigation Without a Mouse

Use the controller as a secondary input device at your desk. Right stick moves the cursor, left stick scrolls, triggers click, face buttons handle Return/Escape/Space/Tab, and the D-Pad gives you arrow keys. Works everywhere -- the default profile matches all apps.

### Presentations and Demos

Walk around freely on stage. Advance slides with A, go back with B, switch to a live demo app with a shoulder button, and point at things on screen with the right stick. Set up per-app profiles so bindings change automatically between Keynote and your demo.

### Accessibility

Full desktop control from a gamepad for users with limited keyboard or mouse access. Mouse, scroll, clicks, and common keys work out of the box. Add layers for extra bindings, toggle hold behavior for sticky modifiers, and macros for multi-step actions.

### Browsing from Bed

Scroll pages with the left stick, aim and click links with the right stick and trigger, press X to pause videos, B to go back. No keyboard needed.

See [docs/use-case-scenarios.md](docs/use-case-scenarios.md) for detailed walkthroughs and button maps for each scenario.

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

### Held Modifier Buttons

To hold Command, Shift, Option, Control, or Fn, bind a button to that modifier's key code with an empty `modifiers` array. Configure these bindings by editing your profile JSON; modifier keys are not yet listed in the app's key picker.

For example, add these entries to `bindings`:

```json
[
  {
    "input": { "type": "single", "element": "Right Shoulder" },
    "action": { "type": "keyPress", "keyCode": 55, "modifiers": [], "key": "Command" }
  },
  {
    "input": { "type": "single", "element": "Left Shoulder" },
    "action": { "type": "keyPress", "keyCode": 56, "modifiers": [], "key": "Shift" }
  },
  {
    "input": { "type": "single", "element": "Direction Pad Left" },
    "action": { "type": "keyPress", "keyCode": 123, "modifiers": [], "key": "Left Arrow" }
  }
]
```

Holding both shoulders and pressing D-pad Left sends Command+Shift+Left. Held modifiers also combine with a key action's explicit `modifiers`. Two buttons may hold the same modifier; it stays active until both are released. Use the default `onPress` behavior to hold a modifier, or `toggle` to keep it active until the next press.

Supported key codes are Command `55` / right Command `54`, Shift `56` / right Shift `60`, Option `58` / right Option `61`, Control `59` / right Control `62`, and Fn `63`. A modifier-key action with a nonempty `modifiers` array keeps its existing shortcut behavior and does not become a held modifier binding.

Triggers can use the same action in their `triggers` configuration. A configured trigger takes precedence over a single-button binding for that input. Held trigger actions are released on profile changes, service stop, and controller disconnect. Cancelling a macro also releases its current held action.

### Hold Behaviors

`onPress` (default), `onRelease`, `whileHeld` (with `repeatIntervalMs`), `toggle`

## License

MIT. See [LICENSE](LICENSE) for details.
