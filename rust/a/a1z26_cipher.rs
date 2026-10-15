/// Encode ASCII letters as their one-based alphabet positions.
#[no_mangle]
pub unsafe extern "C" fn a1z26_cipher(input: *const i64, length: usize,
                                      output: *mut u8, output_capacity: usize) -> i64 {
    if length > 66 { return -1; }
    for index in 0..length {
        let value = *input.add(index);
        if !((65..=90).contains(&value) || (97..=122).contains(&value)) { return -1; }
    }
    if output_capacity < length { return -2; }
    for index in 0..length {
        let value = *input.add(index);
        *output.add(index) = if value >= 97 { (value - 96) as u8 } else { (value - 64) as u8 };
    }
    length as i64
}
