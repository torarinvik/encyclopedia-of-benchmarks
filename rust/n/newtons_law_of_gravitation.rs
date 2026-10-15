/// Solve Newton's law of gravitation for one missing parameter.
const GRAVITATIONAL_CONSTANT: f64 = 6.6743e-11;

#[no_mangle]
pub extern "C" fn newtons_law_of_gravitation(values: *const i64, length: usize) -> f64 {
    if values.is_null() || length != 4 { return -1.0e300; }
    let (target, a, b, c) = unsafe { (*values, *values.add(1), *values.add(2), *values.add(3)) };
    if !(0..=3).contains(&target) || !(1..=1000).contains(&a) || !(1..=1000).contains(&b) || !(1..=1000).contains(&c) {
        return -1.0e300;
    }
    match target {
        0 => GRAVITATIONAL_CONSTANT * (a as f64 * b as f64) / (c as f64 * c as f64),
        1 => a as f64 * (c as f64 * c as f64) / (GRAVITATIONAL_CONSTANT * b as f64),
        2 => a as f64 * (c as f64 * c as f64) / (GRAVITATIONAL_CONSTANT * b as f64),
        _ => (GRAVITATIONAL_CONSTANT * (b as f64 * c as f64) / a as f64).sqrt(),
    }
}
