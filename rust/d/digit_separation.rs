/// Separate signed decimal digits; direction 0 is reverse and 1 is forward.
#[no_mangle]
pub extern "C" fn digit_separation(
    input: *const i64,
    input_length: usize,
    output: *mut u8,
    output_capacity: usize,
) -> i64 {
    if input.is_null() || input_length != 2 { return -1; }
    let values = unsafe { std::slice::from_raw_parts(input, 2) };
    if values[1] != 0 && values[1] != 1 { return -1; }
    let mut remaining = values[0];
    let mut digits = [0u8; 20];
    let mut count = 0usize;
    if remaining == 0 { digits[0] = 0; count = 1; }
    while remaining != 0 {
        let remainder = remaining % 10;
        digits[count] = if remainder < 0 { (-remainder) as u8 } else { remainder as u8 };
        count += 1;
        remaining /= 10;
    }
    if output.is_null() || output_capacity < count { return -2; }
    for index in 0..count {
        let source = if values[1] == 0 { index } else { count - index - 1 };
        unsafe { output.add(index).write(digits[source]); }
    }
    count as i64
}
