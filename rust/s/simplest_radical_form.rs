unsafe fn put_i64(output: *mut u8, offset: usize, value: i64) {
    for (byte, encoded) in value.to_le_bytes().iter().enumerate() {
        *output.add(offset + byte) = *encoded;
    }
}

#[no_mangle]
pub unsafe extern "C" fn simplest_radical_form(
    values: *const i64,
    length: usize,
    output: *mut u8,
    capacity: usize,
) -> i64 {
    if values.is_null() || length != 1 { return -1; }
    let original = *values;
    if original < 0 || original > 100_000_000 { return -1; }
    if output.is_null() || capacity < 16 { return -2; }

    let (mut coefficient, mut root_term) = (1_i64, 1_i64);
    if original == 0 {
        root_term = 0;
    } else {
        let mut remainder = original;
        let mut factor = 2_i64;
        while factor * factor <= original {
            let mut count = 0_i64;
            while remainder % factor == 0 {
                remainder /= factor;
                count += 1;
            }
            for _ in 0..count / 2 { coefficient *= factor; }
            if count % 2 != 0 { root_term *= factor; }
            factor += 1;
        }
        root_term *= remainder;
    }
    put_i64(output, 0, coefficient);
    put_i64(output, 8, root_term);
    16
}
