/// Write lowercase hexadecimal digits of a nonnegative signed 64-bit input.
#[no_mangle]
pub extern "C" fn decimal_to_hexadecimal(value: i64, output: *mut u8, output_capacity: usize) -> i64 {
    if value < 0 { return -1; }
    let mut width = 1usize;
    let mut remaining = value;
    while remaining >= 16 {
        remaining /= 16;
        width += 1;
    }
    if output.is_null() || output_capacity < width { return -2; }
    let mut position = width;
    remaining = value;
    while position > 0 {
        position -= 1;
        let digit = (remaining % 16) as u8;
        let byte = if digit < 10 { b'0' + digit } else { b'a' + digit - 10 };
        unsafe { *output.add(position) = byte; }
        remaining /= 16;
    }
    width as i64
}
