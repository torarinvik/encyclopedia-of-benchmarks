/// Apply an affine conversion in the source operation order: slope * x + intercept.
export fn affine_converter(slope: f64, x: f64, intercept: f64) f64 {
    return slope * x + intercept;
}
