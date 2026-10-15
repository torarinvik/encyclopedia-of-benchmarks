/// Apply the case-preserving Atbash mapping to a 7-bit ASCII byte sequence.
#[no_mangle]
pub unsafe extern "C" fn atbash_cipher(input: *const i64, length: usize,
                                         output: *mut u8, output_capacity: usize) -> i64 {
    if length > 66 { return -1; }
    for index in 0..length {
        let value = *input.add(index);
        if !(0..=127).contains(&value) { return -1; }
    }
    if output_capacity < length { return -2; }
    for index in 0..length {
        let value = *input.add(index);
        let mapped = if (65..=90).contains(&value) {
            155 - value
        } else if (97..=122).contains(&value) {
            219 - value
        } else {
            value
        };
        *output.add(index) = mapped as u8;
    }
    length as i64
}
