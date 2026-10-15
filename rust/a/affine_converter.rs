/// Apply an affine conversion in the source operation order: slope * x + intercept.
#[no_mangle]
pub extern "C" fn affine_converter(slope: f64, x: f64, intercept: f64) -> f64 {
    slope * x + intercept
}
