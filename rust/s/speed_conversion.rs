/// Convert a bounded speed between the five units in the pinned source.
fn round_two_php(value: f64) -> f64 {
    (value * 100.0 + 0.5).floor() / 100.0
}

#[no_mangle]
pub extern "C" fn speed_conversion(speed: f64, route: f64) -> f64 {
    if !(0.0..=1_000_000.0).contains(&speed) || !(0.0..=24.0).contains(&route) || route.fract() != 0.0 {
        return -1.0;
    }
    const FACTORS: [f64; 5] = [1.609344, 1.0, 3.6, 1.097, 1.852];
    const INVERSE_FACTORS: [f64; 5] = [0.6213712, 1.0, 0.277778, 0.911344, 0.539957];
    let encoded = route as usize;
    round_two_php(speed * FACTORS[encoded / 5] * INVERSE_FACTORS[encoded % 5])
}
