const INVALID_RESULT: f64 = -1.0e300;

fn parse_scientific_four(value: f64) -> f64 {
    if value == 0.0 { return 0.0; }
    let mut normalized = value;
    let mut decimal_exponent = 0i32;
    while normalized >= 10.0 { normalized /= 10.0; decimal_exponent += 1; }
    while normalized < 1.0 { normalized *= 10.0; decimal_exponent -= 1; }
    let bits = value.to_bits();
    let fraction = bits & ((1u64 << 52) - 1);
    let exponent_bits = ((bits >> 52) & 0x7ff) as i32;
    let significand = (1u64 << 52) | fraction;
    let binary_exponent = exponent_bits - 1023 - 52;
    let decimal_shift = decimal_exponent - 4;
    let mut denominator = 1u64;
    for _ in 0..decimal_shift { denominator *= 5; }
    let binary_shift = binary_exponent - decimal_shift;
    let mut numerator = significand;
    if binary_shift >= 0 { numerator <<= binary_shift as u32; }
    else { denominator <<= (-binary_shift) as u32; }
    let mut rounded = numerator / denominator;
    let remainder = numerator % denominator;
    if remainder * 2 > denominator || (remainder * 2 == denominator && rounded & 1 != 0) { rounded += 1; }
    let mut decimal_scale = 1.0;
    for _ in 0..decimal_shift { decimal_scale *= 10.0; }
    rounded as f64 * decimal_scale
}

#[no_mangle]
pub unsafe extern "C" fn moles_to_molecules(input: *const i64, length: usize) -> f64 {
    if input.is_null() || length != 1 { return INVALID_RESULT; }
    let values = std::slice::from_raw_parts(input, length);
    let moles_micro = values[0];
    if !(0..=2_000_000).contains(&moles_micro) { return INVALID_RESULT; }
    let moles = moles_micro as f64 / 1_000_000.0;
    let molecules = moles * 6.022e23;
    parse_scientific_four(molecules)
}
