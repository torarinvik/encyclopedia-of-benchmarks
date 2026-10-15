package affine_converter

// Apply an affine conversion in the source operation order: slope * x + intercept.
@(export)
affine_converter :: proc "c" (slope, x, intercept: f64) -> f64 {
    return slope * x + intercept
}
