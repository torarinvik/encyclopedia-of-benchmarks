/// Lowercase ASCII bytes without locale-dependent character handling.
const MAX_LENGTH: usize = 4096;

#[no_mangle]
pub extern "C" fn to_lower_case(input: *const i64, length: usize,
                                 output: *mut u8, output_capacity: usize) -> i64 {
    if length > MAX_LENGTH || (length != 0 && input.is_null()) { return -1; }
    for index in 0..length {
        let value = unsafe { *input.add(index) };
        if !(1..=127).contains(&value) { return -1; }
    }
    if output_capacity < length { return -2; }
    for index in 0..length {
        let mut value = unsafe { *input.add(index) };
        if (65..=90).contains(&value) { value += 32; }
        unsafe { *output.add(index) = value as u8; }
    }
    length as i64
}
