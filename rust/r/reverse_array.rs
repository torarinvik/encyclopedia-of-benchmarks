#[no_mangle]
pub unsafe extern "C" fn reverse_array(input: *const i64, length: usize, output: *mut u8, capacity: usize) -> i64 {
    if length < 1 || length > 257 || input.is_null() { return -1; }
    let count = *input;
    if !(1..=256).contains(&count) || length != count as usize + 1 { return -1; }
    for i in 0..count as usize { let value = *input.add(i + 1); if !(0..=255).contains(&value) { return -1; } }
    if capacity < count as usize || output.is_null() { return -2; }
    for i in 0..count as usize { *output.add(i) = *input.add(i + 1) as u8; }
    let mut left = 0usize; let mut right = count as usize - 1;
    while left < right { let tmp = *output.add(left); *output.add(left) = *output.add(right); *output.add(right) = tmp; left += 1; right -= 1; }
    count
}
