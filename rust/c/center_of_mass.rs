const INVALID_RESULT: f64 = -1.0e300;
const MAX_PARTICLES: i64 = 64;
const MAX_COORDINATE_UNITS: i64 = 1_000_000;
const MAX_MASS_UNITS: i64 = 1_000_000;

// Round the exact binary64 input to cents, matching Python round(value, 2).
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
pub unsafe extern "C" fn center_of_mass(values: *const i64, length: usize) -> f64 {
    if values.is_null() || length < 2 || length > 258 { return INVALID_RESULT; }
    let selector = *values;
    let count_value = *values.add(1);
    if !(0..=2).contains(&selector) || !(1..=MAX_PARTICLES).contains(&count_value)
        || length != 2 + 4 * count_value as usize { return INVALID_RESULT; }
    let count = count_value as usize;
    for index in 0..count {
        let offset = 2 + 4 * index;
        for coordinate in 0..3 {
            let value = *values.add(offset + coordinate);
            if !(-MAX_COORDINATE_UNITS..=MAX_COORDINATE_UNITS).contains(&value) {
                return INVALID_RESULT;
            }
        }
        let mass = *values.add(offset + 3);
        if !(1..=MAX_MASS_UNITS).contains(&mass) { return INVALID_RESULT; }
    }
    let mut total_mass = 0.0;
    for index in 0..count {
        total_mass += *values.add(2 + 4 * index + 3) as f64 / 1000.0;
    }
    let mut weighted_coordinate = 0.0;
    for index in 0..count {
        let offset = 2 + 4 * index;
        let coordinate = *values.add(offset + selector as usize) as f64 / 1000.0;
        let mass = *values.add(offset + 3) as f64 / 1000.0;
        weighted_coordinate += coordinate * mass;
    }
    round_two_python(weighted_coordinate / total_mass)
}
