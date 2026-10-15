/// Convert an ASCII binary string to equal-width ASCII Gray code.
#[no_mangle]
pub unsafe extern "C" fn binary_to_gray(
    bits: *const i64, length: usize, output: *mut u8, output_capacity: usize,
) -> i64 {
    if bits.is_null() || length == 0 || length > 66 { return -1; }
    let bits = std::slice::from_raw_parts(bits, length);
    if bits.iter().any(|&bit| bit != b'0' as i64 && bit != b'1' as i64) { return -1; }
    if output.is_null() || output_capacity < length { return -2; }
    for index in 0..length {
        let current = bits[index] - b'0' as i64;
        let previous = if index == 0 { 0 } else { bits[index - 1] - b'0' as i64 };
        *output.add(index) = (b'0' + (current ^ previous) as u8) as u8;
    }
    length as i64
}
