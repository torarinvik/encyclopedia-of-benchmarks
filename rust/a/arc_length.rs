/// Return arc length; unit 0 uses degrees and unit 1 uses radians.
const PI: f64 = 3.141592653589793238462643383279502884;

#[no_mangle]
pub extern "C" fn arc_length(radius: f64, angle: f64, unit: f64) -> f64 {
    if unit == 0.0 { 2.0 * PI * radius * (angle / 360.0) } else { radius * angle }
}
