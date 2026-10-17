const INVALID_RESULT: f64 = -1.0e300;

fn round_binary64_to_hundredth(value: f64) -> f64 {
    if value == 0.0 {
        return 0.0;
    }
    let bits = value.to_bits();
    let fraction = bits & ((1u64 << 52) - 1);
    let exponent_bits = ((bits >> 52) & 0x7ff) as i32;
    let significand = (1u64 << 52) | fraction;
    let binary_exponent = exponent_bits - 1023 - 52;
    let shift = (-binary_exponent) as u32;
    let scaled_significand = significand * 100;
    let denominator = 1u64 << shift;
    let mut hundredths = scaled_significand >> shift;
    let remainder = scaled_significand & (denominator - 1);
    let halfway = denominator >> 1;
    if remainder > halfway || (remainder == halfway && hundredths & 1 != 0) {
        hundredths += 1;
    }
    hundredths as f64 / 100.0
}

#[no_mangle]
pub unsafe extern "C" fn mass_to_moles(input: *const i64, length: usize) -> f64 {
    if input.is_null() || length != 2 {
        return INVALID_RESULT;
    }
    let values = std::slice::from_raw_parts(input, length);
    let mass = values[0];
    let molar_mass = values[1];
    if !(0..=1000).contains(&mass) || !(1..=1000).contains(&molar_mass) {
        return INVALID_RESULT;
    }
    round_binary64_to_hundredth(mass as f64 / molar_mass as f64)
}
