/// Convert a bounded exactly representable finite decimal to a reduced fraction.
const POWERS10: [i64; 5] = [1, 10, 100, 1000, 10000];
const POWERS5: [i64; 5] = [1, 5, 25, 125, 625];

fn store_i64_le(output: &mut [u8], offset: usize, value: i64) {
    output[offset..offset + 8].copy_from_slice(&value.to_le_bytes());
}

fn gcd_positive(mut a: i64, mut b: i64) -> i64 {
    while b != 0 { let remainder = a % b; a = b; b = remainder; }
    a
}

#[no_mangle]
pub unsafe extern "C" fn decimal_to_fraction(values: *const i64, length: usize,
    output: *mut u8, capacity: usize) -> i64 {
    if values.is_null() || length != 2 { return -1; }
    let input = std::slice::from_raw_parts(values, length);
    let mantissa = input[0];
    let places_value = input[1];
    if !(0..=4).contains(&places_value) { return -1; }
    let places = places_value as usize;
    let scale = POWERS10[places];
    let maximum_mantissa = 1_000_000i64 * scale;
    if mantissa < -maximum_mantissa || mantissa > maximum_mantissa || mantissa % POWERS5[places] != 0 { return -1; }
    if output.is_null() || capacity < 16 { return -2; }
    let out = std::slice::from_raw_parts_mut(output, 16);

    let decimal = mantissa as f64 / scale as f64;
    let (numerator, denominator) = if decimal - decimal.trunc() == 0.0 {
        (decimal as i64, 1i64)
    } else {
        let mut digits = places;
        let mut magnitude = mantissa.abs();
        while digits > 0 && magnitude % 10 == 0 { magnitude /= 10; digits -= 1; }
        let numerator = (decimal * POWERS10[digits] as f64) as i64;
        let denominator = POWERS10[digits];
        let gcd = gcd_positive(numerator.abs(), denominator);
        (numerator / gcd, denominator / gcd)
    };
    store_i64_le(out, 0, numerator);
    store_i64_le(out, 8, denominator);
    16
}
