class Joymapkit < Formula
  desc "Map gamepad inputs to keyboard, mouse, and macros on macOS"
  homepage "https://github.com/manaporkun/JoyMapKit"
  license "MIT"

  # Updated automatically by release workflow
  url "https://github.com/manaporkun/JoyMapKit/archive/refs/tags/v0.1.0.tar.gz"
  sha256 ""
  version "0.1.0"

  depends_on xcode: ["15.0", :build]
  depends_on :macos

  def install
    system "swift", "build",
           "-c", "release",
           "--disable-sandbox",
           "-Xswiftc", "-cross-module-optimization"
    bin.install ".build/release/joymapkit"
  end

  def caveats
    <<~EOS
      JoyMapKit requires macOS Accessibility permission to simulate key/mouse events.
      Grant access in System Settings > Privacy & Security > Accessibility.

      To start the mapping service:
        joymapkit run

      Default config directory: ~/.config/joymapkit/
      Copy example profiles from: #{opt_prefix}/share/joymapkit/profiles/
    EOS
  end

  test do
    assert_match "joymapkit", shell_output("#{bin}/joymapkit --help")
  end
end
