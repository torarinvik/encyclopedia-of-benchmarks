/// Perimeter and area calculations for a bounded circle radius.
const INVALID_RESULT: f64 = -1.0e300;
const PI: f64 = 3.14159265358979323846;

#[no_mangle]
pub extern "C" fn circle(radius: f64, operation: f64) -> f64 {
    if !radius.is_finite() || !operation.is_finite() ||
        !(-1_000_000.0..=1_000_000.0).contains(&radius) ||
        (operation != 0.0 && operation != 1.0) {
        return INVALID_RESULT;
    }
    if operation == 0.0 { radius * 2.0 * PI } else { radius.powf(2.0) * PI }
}
