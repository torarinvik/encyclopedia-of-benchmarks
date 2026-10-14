/// Apply ROT13 only to lowercase non-NUL ASCII bytes.
#[no_mangle]
pub unsafe extern "C" fn theoretical_rot13(input: *const i64, length: usize,
                                              output: *mut u8, output_capacity: usize) -> i64 {
    if length > 66 { return -1; }
    for index in 0..length {
        let value = *input.add(index);
        if !(1..=127).contains(&value) { return -1; }
    }
    if output_capacity < length { return -2; }
    for index in 0..length {
        let value = *input.add(index);
        let mapped = if (b'a' as i64..=b'z' as i64).contains(&value) {
            b'a' as i64 + (value - b'a' as i64 + 13) % 26
        } else {
            value
        };
        *output.add(index) = mapped as u8;
    }
    length as i64
}
