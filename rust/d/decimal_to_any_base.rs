/// Convert a nonnegative signed 64-bit value to base 2 through 36.
#[no_mangle]
pub unsafe extern "C" fn decimal_to_any_base(input: *const i64, length: usize,
                                               output: *mut u8, output_capacity: usize) -> i64 {
    if input.is_null() || length != 2 { return -1; }
    let value = *input;
    let base = *input.add(1);
    if value < 0 || !(2..=36).contains(&base) { return -1; }
    let mut width = 1usize;
    let mut remaining = value;
    while remaining >= base {
        remaining /= base;
        width += 1;
    }
    if output.is_null() || output_capacity < width { return -2; }
    let mut position = width;
    remaining = value;
    while position > 0 {
        position -= 1;
        let digit = remaining % base;
        *output.add(position) = if digit < 10 { b'0' + digit as u8 } else { b'A' + (digit - 10) as u8 };
        remaining /= base;
    }
    width as i64
}
