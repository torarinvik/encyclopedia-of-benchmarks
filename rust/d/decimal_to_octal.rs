/// Write the octal digits of a nonnegative signed 64-bit input.
#[no_mangle]
pub extern "C" fn decimal_to_octal(value: i64, output: *mut u8, output_capacity: usize) -> i64 {
    if value < 0 { return -1; }
    let mut width = 1usize;
    let mut remaining = value;
    while remaining >= 8 {
        remaining /= 8;
        width += 1;
    }
    if output.is_null() || output_capacity < width { return -2; }
    let mut position = width;
    remaining = value;
    while position > 0 {
        position -= 1;
        unsafe { *output.add(position) = b'0' + (remaining % 8) as u8; }
        remaining /= 8;
    }
    width as i64
}
