use std::ffi::c_double;
const INVALID_RESULT: f64 = -1.0e300;
fn round_two_python(value: f64) -> f64 {
    if value == 0.0 { return value; }
    let negative = value < 0.0;
    let mut normalized = if negative { -value } else { value };
    let mut exponent = 0i32;
    while normalized >= 1.0 { normalized *= 0.5; exponent += 1; }
    while normalized < 0.5 { normalized *= 2.0; exponent -= 1; }
    let significand = (normalized * 9_007_199_254_740_992.0) as u64;
    let numerator = significand * 100;
    let shift = 53 - exponent;
    let mut cents = 0u64;
    if shift < 0 { cents = numerator << ((-shift) as u32); }
    else if shift == 0 { cents = numerator; }
    else if shift < 64 {
        let denominator = 1u64 << shift as u32;
        cents = numerator >> shift as u32;
        let remainder = numerator & (denominator - 1);
        let half = denominator >> 1;
        if remainder > half || (remainder == half && (cents & 1) != 0) { cents += 1; }
    }
    let rounded = cents as f64 / 100.0;
    if negative { -rounded } else { rounded }
}
#[no_mangle]
pub unsafe extern "C" fn present_value(values: *const i64, length: usize) -> c_double {
    if values.is_null() || length < 3 || length > 10 { return INVALID_RESULT; }
    let count_value = *values;
    let rate_ppm = *values.add(1);
    if !(1..=8).contains(&count_value) || length != 2 + count_value as usize || ![0, 1_000_000].contains(&rate_ppm) { return INVALID_RESULT; }
    for i in 0..count_value as usize {
        let flow = *values.add(i + 2);
        if !(-1_000_000..=1_000_000).contains(&flow) || flow % 125 != 0 { return INVALID_RESULT; }
    }
    let rate = rate_ppm as f64 / 1_000_000.0;
    let mut total = 0.0;
    for i in 0..count_value as usize {
        let flow = *values.add(i + 2) as f64 / 1000.0;
        total += flow / (1.0 + rate).powf(i as f64);
    }
    round_two_python(total)
}
