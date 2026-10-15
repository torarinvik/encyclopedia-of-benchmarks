module affine_converter;

// Apply an affine conversion in the source operation order: slope * x + intercept.
fn double affine_converter(double slope, double x, double intercept) @export("affine_converter") {
    return slope * x + intercept;
}
