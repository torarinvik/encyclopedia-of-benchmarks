/// Solve Boyle's law for one omitted variable, rounded to 3 decimals.
fn rounded_milli(numerator: i64, denominator: i64) -> i64 {
    let scaled = numerator * 1000;
    let mut quotient = scaled / denominator;
    let remainder = scaled % denominator;
    if 2 * remainder > denominator || (2 * remainder == denominator && quotient % 2 != 0) {
        quotient += 1;
    }
    quotient
}

#[no_mangle]
pub extern "C" fn boyles_law(values: *const i64, length: usize) -> f64 {
    if values.is_null() || length != 4 { return -1.0e300; }
    let (target, a, b, c) = unsafe { (*values, *values.add(1), *values.add(2), *values.add(3)) };
    if !(0..=3).contains(&target) || !(1..=1000).contains(&a) || !(1..=1000).contains(&b) || !(1..=1000).contains(&c) {
        return -1.0e300;
    }
    let (numerator, denominator) = match target {
        0 => (c * a, b),
        1 => (b * a, c),
        2 => (c * b, a),
        _ => (c * a, b),
    };
    rounded_milli(numerator, denominator) as f64 / 1000.0
}
