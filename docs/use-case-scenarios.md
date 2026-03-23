# How People Use JoyMapKit

Real scenarios showing how JoyMapKit fits into everyday workflows.

---

## Coding from the Couch with Claude Code

You're pair-programming with Claude Code in Ghostty, but you're leaned back on the couch with a DualSense controller instead of hunched over a keyboard.

**The setup:** JoyMapKit auto-switches to the `ghostty-terminal` profile when Ghostty is focused.

| Controller | Action |
|---|---|
| B (Circle) | Space -- activates Claude Code voice mode, so you talk instead of type |
| A (Cross) | Return -- accepts suggestions, confirms prompts |
| D-Pad Up/Down | Arrow keys -- scroll through command history and output |
| D-Pad Left/Right | Ctrl+Shift+Tab / Ctrl+Tab -- switch between terminal tabs |
| Right Stick | Move the mouse cursor to click on things |
| Left Stick | Scroll through long code output |
| Right Trigger | Left click |
| Left Trigger | Right click |
| Menu (turbo) | Hold + any button for rapid-fire repeats |

You press B to start voice mode, describe what you want Claude to build, read the output by scrolling with the left stick, and press A to accept. When you need to switch to a browser tab to check docs, Cmd+Tab takes you to Safari and JoyMapKit swaps to the default profile automatically.

**Included profile:** `Examples/profiles/ghostty-terminal.json`

---

## Desktop Navigation Without a Mouse

You have a controller on your desk as a secondary input device. Instead of reaching for the mouse to scroll a webpage or click a link, you use the controller.

**The setup:** The `default` profile matches all apps (`"*"`).

| Controller | Action |
|---|---|
| Right Stick | Mouse cursor |
| Left Stick | Scroll |
| Right Trigger | Left click |
| Left Trigger | Right click |
| A | Return |
| B | Escape |
| X | Space (play/pause, page down) |
| Y | Tab (cycle through form fields) |
| D-Pad | Arrow keys |
| LB / RB | Shift+Tab / Tab (navigate backwards/forwards) |

You're reading a long article -- tilt the left stick to scroll at exactly the speed you want. Need to click a link? Aim with the right stick, squeeze the trigger. Tab through a form with Y. It's a mouse replacement that never leaves your hand.

**Included profile:** `Examples/profiles/default.json`

---

## Terminal Power User

You live in the terminal and want quick access to common shortcuts without leaving the controller.

**The setup:** The `claude-code` profile maps every button to a productivity shortcut.

| Controller | Action |
|---|---|
| A | Return |
| B | Escape |
| X | Space |
| Y | Tab |
| LB | Cmd+Z (undo) |
| RB | Cmd+Shift+Z (redo) |
| D-Pad Left/Right | Cmd+Left / Cmd+Right (jump to line start/end) |
| D-Pad Up/Down | Arrow keys |
| Menu | Cmd+K (clear terminal) |
| Options | Cmd+P (command palette) |
| Left Stick Click | Cmd+C (copy) |
| Right Stick Click | Cmd+V (paste) |

You're reviewing a diff. Scroll through it with the left stick, copy a snippet by clicking the left stick, switch to another tab, and paste with the right stick click. Undo something with LB. Clear the terminal with Menu. All without touching the keyboard.

**Included profile:** `Examples/profiles/claude-code.json`

---

## Presentations and Demo Mode

You're presenting on stage or screen-sharing and want to control slides and navigate your demo without being tied to a laptop.

**How to set it up:**
- Map A to Right Arrow (next slide) and B to Left Arrow (previous slide)
- Map X to Space for play/pause in video demos
- Use the right stick as a mouse to point at things on screen
- Map a shoulder button to Cmd+Tab to switch between your slides and a live demo app
- Set up per-app profiles: one for Keynote, one for your demo app

You walk around freely, advance slides with A, switch to a live terminal demo with RB, scroll through code with the left stick, then switch back to slides.

---

## Accessibility - Full Desktop Control

You have limited use of a keyboard and mouse but can comfortably hold a gamepad. JoyMapKit turns it into a complete desktop input device.

**What you get out of the box with the default profile:**
- Mouse cursor via right stick (adjustable sensitivity and response curve for precision)
- Scrolling via left stick
- Left/right click via triggers (adjustable threshold for how hard you need to pull)
- Return, Escape, Space, Tab, and arrow keys on face buttons and D-Pad
- Per-app auto-switching so bindings adapt to whatever you're using

**To go further:**
- Add layers: hold a shoulder button to access a second set of bindings (Cmd+C, Cmd+V, Cmd+A, etc.)
- Use toggle hold behavior for sticky modifiers (press Y once to hold Shift, press again to release)
- Set up macros for multi-step actions (select all + copy in one button press)
- Use turbo for rapid-fire key repeats

This covers web browsing, document editing, file management, and app navigation entirely from the controller.

---

## Browsing the Web from Bed

Late night scrolling -- you're in bed with a controller reading Reddit, YouTube, or docs.

**Key mappings:**
- Left stick scrolls pages at variable speed
- Right stick moves the cursor to click links and buttons
- A (Return) opens links, B (Escape) goes back
- X (Space) pauses/plays videos and page-scrolls
- D-Pad navigates between focusable elements
- Triggers click

You scroll through a page with the left stick, spot a link, nudge the right stick to aim, squeeze the right trigger to click. Press B to go back. Press X to pause a video. No keyboard, no mouse, no getting out of bed.

---

## Creating Your Own Scenario

Every scenario above is just a JSON profile. To build your own:

1. Open the profile editor from the menu bar
2. Click "+" to create a new profile
3. Set `appBundleIDs` to target specific apps (or `["*"]` for all)
4. Use "Press to Assign" to capture controller inputs without memorizing button names
5. Configure stick modes, deadzones, and response curves to taste
6. Save -- it's live immediately

Profiles are stored in `~/.config/joymapkit/profiles/` and can be shared as plain JSON files.
