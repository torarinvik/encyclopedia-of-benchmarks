/// Convert a nonnegative signed 64-bit value with a LIFO digit stack.
#[no_mangle]
pub unsafe extern "C" fn decimal_to_any_using_stack(input: *const i64, length: usize,
                                                        output: *mut u8, output_capacity: usize) -> i64 {
    if input.is_null() || length != 2 { return -1; }
    let value = *input;
    let base = *input.add(1);
    if value < 0 || !(2..=16).contains(&base) { return -1; }
    let mut width = 1usize;
    let mut remaining = value;
    while remaining >= base { remaining /= base; width += 1; }
    if output.is_null() || output_capacity < width { return -2; }
    let mut top = 0usize;
    remaining = value;
    if remaining == 0 { *output.add(top) = b'0'; top += 1; }
    while remaining > 0 {
        let digit = remaining % base;
        *output.add(top) = if digit < 10 { b'0' + digit as u8 } else { b'A' + (digit - 10) as u8 };
        top += 1;
        remaining /= base;
    }
    let mut left = 0usize;
    let mut right = top - 1;
    while left < right {
        let temporary = *output.add(left);
        *output.add(left) = *output.add(right);
        *output.add(right) = temporary;
        left += 1;
        right -= 1;
    }
    top as i64
}
