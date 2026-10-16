const INVALID_RESULT: f64 = -1.0e300;

fn round_five_even(value: f64) -> f64 {
    let scaled = value * 100_000.0;
    let fraction = scaled - scaled.floor();
    if (fraction - 0.5).abs() <= 1.0e-7 { return INVALID_RESULT; }
    if value == 0.0 { return value; }
    let negative = value < 0.0;
    let mut normalized = value.abs();
    let mut exponent = 0i32;
    while normalized < 1.0 { normalized *= 2.0; exponent -= 1; }
    while normalized >= 2.0 { normalized *= 0.5; exponent += 1; }
    let mantissa = (normalized * 4_503_599_627_370_496.0) as u64;
    let shift = 52 - exponent;
    if shift > 70 { return if negative { -0.0 } else { 0.0 }; }
    let low_product = (mantissa & 0xffff_ffff) * 100_000;
    let high_product = (mantissa >> 32) * 100_000;
    let shifted_high = high_product << 32;
    let (low, carry) = low_product.overflowing_add(shifted_high);
    let high = (high_product >> 32) + if carry { 1 } else { 0 };
    let quotient = if shift < 64 { (low >> shift) | (high << (64 - shift)) } else { high >> (shift - 64) };
    let half_bit = if shift - 1 < 64 { (low >> (shift - 1)) & 1 } else { (high >> (shift - 65)) & 1 };
    let lower_bits = if shift - 1 < 64 {
        low & ((1u64 << (shift - 1)) - 1) != 0
    } else {
        low != 0 || (high & ((1u64 << (shift - 65)) - 1)) != 0
    };
    let rounded = quotient + if half_bit != 0 && (lower_bits || quotient & 1 != 0) { 1 } else { 0 };
    let result = rounded as f64 / 100_000.0;
    if negative { -result } else { result }
}

#[no_mangle]
pub extern "C" fn light_aberration(values: *const i64, length: usize) -> f64 {
    if values.is_null() || length != 2 { return INVALID_RESULT; }
    let theta_code = unsafe { *values };
    let beta_code = unsafe { *values.add(1) };
    if !(-3_141_592..=3_141_592).contains(&theta_code) || !(0..=999_999).contains(&beta_code) { return INVALID_RESULT; }
    let theta = theta_code as f64 / 1_000_000.0;
    let beta = beta_code as f64 / 1_000_000.0;
    let factor = ((1.0 - beta) / (1.0 + beta)).sqrt();
    let angle = 2.0 * (factor * (theta / 2.0).tan()).atan();
    round_five_even(angle)
}
