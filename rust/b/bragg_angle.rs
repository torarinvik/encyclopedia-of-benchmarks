/// Bragg diffraction angle, rounded to one decimal degree.
const PI: f64 = 3.141592653589793238462643383279502884;

fn round_one_even(value: f64) -> f64 {
    let scaled = value * 10.0;
    let lower = scaled.floor();
    let fraction = scaled - lower;
    let mut rounded = lower as i64;
    if fraction > 0.5 || (fraction == 0.5 && rounded % 2 != 0) {
        rounded += 1;
    }
    rounded as f64 / 10.0
}

#[no_mangle]
pub extern "C" fn bragg_angle(values: *const i64, length: usize) -> f64 {
    if values.is_null() || length != 3 { return -1.0e300; }
    let (distance, order, wavelength) = unsafe { (*values, *values.add(1), *values.add(2)) };
    if !(1..=1_000_000).contains(&distance) || !(-1000..=1000).contains(&order) || !(0..=1_000_000).contains(&wavelength) {
        return -1.0e300;
    }
    let sine = (order as f64 * wavelength as f64) / (2.0 * distance as f64);
    if !(-1.0..=1.0).contains(&sine) { return -1.0e300; }
    let degrees = sine.asin() * (180.0 / PI);
    round_one_even(degrees)
}
