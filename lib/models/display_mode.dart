/// Video display mode for the session renderer.
enum DisplayMode {
  /// Maintain aspect ratio with potential letter/pillar boxing.
  contain,

  /// Stretch to fill the available space (may distort aspect ratio).
  cover,

  /// Fit the content, stretching on mobile to match a wider aspect ratio.
  fit,
}
