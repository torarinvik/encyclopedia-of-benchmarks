/// Write the most-significant-first binary representation of a nonnegative i64.
#[no_mangle]
pub extern "C" fn decimal_to_binary(value: i64, output: *mut u8, output_capacity: usize) -> i64 {
    if value < 0 {
        return -1;
    }

    let mut width = 1usize;
    let mut remaining = value;
    while remaining > 1 {
        remaining /= 2;
        width += 1;
    }
    if output.is_null() || output_capacity < width {
        return -2;
    }

    let mut position = width;
    remaining = value;
    while position > 0 {
        position -= 1;
        unsafe { *output.add(position) = b'0' + (remaining % 2) as u8; }
        remaining /= 2;
    }
    width as i64
}
