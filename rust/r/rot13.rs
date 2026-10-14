/// Apply case-preserving ROT13 to a non-NUL ASCII byte sequence.
#[no_mangle]
pub unsafe extern "C" fn rot13(input: *const i64, length: usize,
                                  output: *mut u8, output_capacity: usize) -> i64 {
    if length > 66 { return -1; }
    for index in 0..length {
        let value = *input.add(index);
        if !(1..=127).contains(&value) { return -1; }
    }
    if output_capacity < length { return -2; }
    for index in 0..length {
        let value = *input.add(index);
        let mapped = if (b'A' as i64..=b'Z' as i64).contains(&value) {
            b'A' as i64 + (value - b'A' as i64 + 13) % 26
        } else if (b'a' as i64..=b'z' as i64).contains(&value) {
            b'a' as i64 + (value - b'a' as i64 + 13) % 26
        } else {
            value
        };
        *output.add(index) = mapped as u8;
    }
    length as i64
}
