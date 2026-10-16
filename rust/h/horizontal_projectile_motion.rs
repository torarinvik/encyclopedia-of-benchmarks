const GRAVITY: f64 = 9.80665;
const OUTPUT_BYTES: i64 = 24;

fn round_cents(value: f64) -> i64 {
    let bits = value.to_bits();
    let exponent = ((bits >> 52) & 2047) as i32;
    if exponent == 0 { return 0; }
    let mantissa = (1_u64 << 52) | (bits & 4503599627370495);
    let product = mantissa * 25;
    let right_shift = 1073 - exponent;
    if right_shift >= 59 { return 0; }
    let mut rounded = product >> right_shift;
    let divisor = 1_u64 << right_shift;
    let remainder = product & (divisor - 1);
    let halfway = divisor >> 1;
    if remainder > halfway || (remainder == halfway && rounded & 1 != 0) { rounded += 1; }
    if bits >> 63 != 0 { -(rounded as i64) } else { rounded as i64 }
}

fn store_f64_le(output: &mut [u8], offset: usize, value: f64) {
    let bits = value.to_bits();
    for byte in 0..8 { output[offset + byte] = (bits >> (8 * byte)) as u8; }
}

#[no_mangle]
pub unsafe extern "C" fn horizontal_projectile_motion(values: *const i64, length: usize,
        output: *mut u8, output_capacity: usize) -> i64 {
    if values.is_null() || length != 2 { return -1; }
    let input = std::slice::from_raw_parts(values, length);
    let velocity_milli = input[0];
    let angle_millidegrees = input[1];
    if !(0..=100_000).contains(&velocity_milli) || !(1_000..=90_000).contains(&angle_millidegrees) {
        return -1;
    }
    if output.is_null() || output_capacity < OUTPUT_BYTES as usize { return -2; }

    let velocity = velocity_milli as f64 / 1000.0;
    let angle = angle_millidegrees as f64 / 1000.0;
    let pi_over_180 = 3.14159265358979323846264338327950288_f64 / 180.0;
    let distance_raw = velocity * velocity * ((2.0 * angle) * pi_over_180).sin() / GRAVITY;
    let angle_sine = (angle * pi_over_180).sin();
    let height_raw = velocity * velocity * angle_sine * angle_sine / (2.0 * GRAVITY);
    let time_raw = (2.0 * velocity) * angle_sine / GRAVITY;
    let output_slice = std::slice::from_raw_parts_mut(output, OUTPUT_BYTES as usize);
    store_f64_le(output_slice, 0, round_cents(distance_raw) as f64 / 100.0);
    store_f64_le(output_slice, 8, round_cents(height_raw) as f64 / 100.0);
    store_f64_le(output_slice, 16, round_cents(time_raw) as f64 / 100.0);
    OUTPUT_BYTES
}
