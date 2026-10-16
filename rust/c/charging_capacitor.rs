const INVALID_RESULT: f64 = -1.0e300;

fn round_three_python(value: f64) -> f64 {
    if value == 0.0 { return value; }
    let negative = value < 0.0;
    let mut normalized = if negative { -value } else { value };
    let mut exponent = 0i32;
    while normalized >= 1.0 { normalized *= 0.5; exponent += 1; }
    while normalized < 0.5 { normalized *= 2.0; exponent -= 1; }
    let significand = (normalized * 9_007_199_254_740_992.0) as u64;
    let numerator = significand * 1000;
    let shift = 53 - exponent;
    let mut milliunits = 0u64;
    if shift < 0 { milliunits = numerator << ((-shift) as u32); }
    else if shift == 0 { milliunits = numerator; }
    else if shift < 64 {
        let denominator = 1u64 << shift as u32;
        milliunits = numerator >> shift as u32;
        let remainder = numerator & (denominator - 1);
        let half = denominator >> 1;
        if remainder > half || (remainder == half && (milliunits & 1) != 0) { milliunits += 1; }
    }
    let rounded = milliunits as f64 / 1000.0;
    if negative { -rounded } else { rounded }
}

#[no_mangle]
pub unsafe extern "C" fn charging_capacitor(values: *const i64, length: usize) -> f64 {
    if values.is_null() || length != 4 { return INVALID_RESULT; }
    let voltage_micro = *values;
    let resistance_micro = *values.add(1);
    let capacitance_micro = *values.add(2);
    let time_micro = *values.add(3);
    if !(1..=1_000_000_000_000).contains(&voltage_micro)
        || !(1..=1_000_000_000_000_000).contains(&resistance_micro)
        || !(1..=1_000_000_000_000).contains(&capacitance_micro)
        || !(-1_000_000_000_000..=1_000_000_000_000).contains(&time_micro) {
        return INVALID_RESULT;
    }
    let source_voltage = voltage_micro as f64 / 1_000_000.0;
    let resistance = resistance_micro as f64 / 1_000_000.0;
    let capacitance = capacitance_micro as f64 / 1_000_000.0;
    let time_sec = time_micro as f64 / 1_000_000.0;
    let exponent = -time_sec / (resistance * capacitance);
    if exponent > 10.0 { return INVALID_RESULT; }
    round_three_python(source_voltage * (1.0 - exponent.exp()))
}
