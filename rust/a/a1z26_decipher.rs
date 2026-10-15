/// Decode one-based alphabet positions as lowercase ASCII letters.
#[no_mangle]
pub unsafe extern "C" fn a1z26_decipher(input: *const i64, length: usize,
                                        output: *mut u8, output_capacity: usize) -> i64 {
    if length > 66 { return -1; }
    for index in 0..length {
        let value = *input.add(index);
        if !(1..=26).contains(&value) { return -1; }
    }
    if output_capacity < length { return -2; }
    for index in 0..length {
        *output.add(index) = (96 + *input.add(index)) as u8;
    }
    length as i64
}
