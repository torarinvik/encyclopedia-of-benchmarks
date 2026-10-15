/// Write the minimal-width ASCII binary form of n ^ (n >> 1).
#[no_mangle]
pub unsafe extern "C" fn decimal_to_gray(
    value: i64,
    output: *mut u8,
    output_capacity: usize,
) -> i64 {
    if value < 0 {
        return -1;
    }

    let gray = value ^ (value >> 1);
    let mut width = 1usize;
    let mut remaining = gray;
    while remaining > 1 {
        remaining /= 2;
        width += 1;
    }
    if output.is_null() || output_capacity < width {
        return -2;
    }

    let mut position = width;
    remaining = gray;
    while position > 0 {
        position -= 1;
        *output.add(position) = b'0' + (remaining % 2) as u8;
        remaining /= 2;
    }
    width as i64
}
