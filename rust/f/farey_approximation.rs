fn store_i64_le(output: &mut [u8], offset: usize, value: i64) {
    let bits = value as u64;
    for byte in 0..8 {
        output[offset + byte] = ((bits >> (byte * 8)) & 0xff) as u8;
    }
}

#[no_mangle]
pub unsafe extern "C" fn farey_approximation(
    values: *const i64,
    length: usize,
    output: *mut u8,
    capacity: usize,
) -> i64 {
    if values.is_null() || length != 2 { return -1; }
    let input = std::slice::from_raw_parts(values, length);
    let decimal_millionths = input[0];
    let repeat = input[1];
    if !(1..=999_999).contains(&decimal_millionths) || !(1..=20).contains(&repeat) { return -1; }
    if output.is_null() || capacity < 16 { return -2; }
    let result = std::slice::from_raw_parts_mut(output, capacity);

    let decimal = decimal_millionths as f64 / 1_000_000.0;
    let (mut a, mut b, mut c, mut d) = (0_i64, 1_i64, 1_i64, 1_i64);
    let (mut numerator, mut denominator) = (0_i64, 0_i64);
    for _ in 0..repeat {
        numerator = a + c;
        denominator = b + d;
        if decimal > numerator as f64 / denominator as f64 {
            a = numerator;
            b = denominator;
        } else {
            c = numerator;
            d = denominator;
        }
    }
    store_i64_le(result, 0, numerator);
    store_i64_le(result, 8, denominator);
    16
}
