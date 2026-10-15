/// Convert a bounded speed between the four units in the pinned source.
fn round_three_even(value: f64) -> f64 {
    let lower = (value * 1000.0).floor();
    let midpoint = lower + 0.5;
    let exact_side = value.mul_add(1000.0, -midpoint);
    let mut rounded = lower as i64;
    if exact_side > 0.0 || (exact_side == 0.0 && rounded % 2 != 0) { rounded += 1; }
    rounded as f64 / 1000.0
}

#[no_mangle]
pub extern "C" fn speed_conversions(speed: f64, route: f64) -> f64 {
    if !(0.0..=1_000_000.0).contains(&speed) || !(0.0..=15.0).contains(&route) || route.fract() != 0.0 {
        return -1.0;
    }
    const FACTORS: [f64; 4] = [1.0, 3.6, 1.609344, 1.852];
    const INVERSE_FACTORS: [f64; 4] = [1.0, 0.277777778, 0.621371192, 0.539956803];
    let encoded = route as usize;
    round_three_even(speed * FACTORS[encoded / 4] * INVERSE_FACTORS[encoded % 4])
}
