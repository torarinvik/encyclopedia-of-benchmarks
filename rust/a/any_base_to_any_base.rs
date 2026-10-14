/// Convert a radix digit array through checked decimal accumulation.
#[no_mangle]
pub unsafe extern "C" fn any_base_to_any_base(input: *const i64, length: usize,
                                                output: *mut u8, output_capacity: usize) -> i64 {
    if input.is_null() || !(3..=65).contains(&length) { return -1; }
    let source_base = *input;
    let target_base = *input.add(1);
    if !(2..=36).contains(&source_base) || !(2..=36).contains(&target_base) { return -1; }
    let mut value = 0i64;
    for index in 2..length {
        let digit = *input.add(index);
        if digit < 0 || digit >= source_base { return -1; }
        if value > (i64::MAX - digit) / source_base { return -1; }
        value = value * source_base + digit;
    }
    let mut width = 1usize;
    let mut remaining = value;
    while remaining >= target_base { remaining /= target_base; width += 1; }
    if output.is_null() || output_capacity < width { return -2; }
    let mut top = 0usize;
    remaining = value;
    if remaining == 0 { *output.add(top) = b'0'; top += 1; }
    while remaining > 0 {
        let digit = remaining % target_base;
        *output.add(top) = if digit < 10 { b'0' + digit as u8 } else { b'A' + (digit - 10) as u8 };
        top += 1;
        remaining /= target_base;
    }
    let mut left = 0usize;
    let mut right = top - 1;
    while left < right {
        let temporary = *output.add(left);
        *output.add(left) = *output.add(right);
        *output.add(right) = temporary;
        left += 1; right -= 1;
    }
    top as i64
}
