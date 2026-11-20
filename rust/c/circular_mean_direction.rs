const PI_VALUE: f64 = 3.14159265358979323846264338327950288;
const TAU_VALUE: f64 = 6.28318530717958647692528676655900576;
const CUTOFF_SCALE: f64 = 0.0000000037252902984619140625;

fn wrap_angle(angle: f64) -> f64 {
    let mut value = angle - ((angle + PI_VALUE) / TAU_VALUE).floor() * TAU_VALUE;
    if value >= PI_VALUE { value -= TAU_VALUE; }
    if value < -PI_VALUE { value += TAU_VALUE; }
    value
}

#[no_mangle]
pub unsafe extern "C" fn circular_mean_direction(
    input: *const f64, length: usize, output: *mut f64, capacity: usize,
) -> i64 {
    if input.is_null() || length < 2 || length > 66 { return -1; }
    let values = std::slice::from_raw_parts(input, length);
    let count_value = values[0];
    if !count_value.is_finite() || count_value.fract() != 0.0 ||
        !(1.0..=64.0).contains(&count_value) { return -1; }
    let count = count_value as usize;
    if length != count + 1 { return -1; }

    let mut sum_cos = 0.0;
    let mut sum_sin = 0.0;
    let mut correction_cos = 0.0;
    let mut correction_sin = 0.0;
    for &raw in &values[1..] {
        if !raw.is_finite() || raw.abs() > 8.0 * PI_VALUE { return -1; }
        let angle = wrap_angle(raw);
        let adjusted_cos = angle.cos() - correction_cos;
        let next_cos = sum_cos + adjusted_cos;
        correction_cos = (next_cos - sum_cos) - adjusted_cos;
        sum_cos = next_cos;
        let adjusted_sin = angle.sin() - correction_sin;
        let next_sin = sum_sin + adjusted_sin;
        correction_sin = (next_sin - sum_sin) - adjusted_sin;
        sum_sin = next_sin;
    }
    let resultant = (sum_cos * sum_cos + sum_sin * sum_sin).sqrt();
    if !resultant.is_finite() || resultant <= count as f64 * CUTOFF_SCALE { return -1; }
    if output.is_null() || capacity < 1 { return -2; }
    *output = wrap_angle(sum_sin.atan2(sum_cos));
    1
}
