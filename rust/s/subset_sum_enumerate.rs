/// Emit the index masks of all signed subsets matching the target.
#[no_mangle]
pub extern "C" fn subset_sum_enumerate(
    input: *const i64, length: usize, output: *mut u8, output_capacity: usize,
) -> i64 {
    if length == 0 || length > 9 { return -1; }
    let input = unsafe { std::slice::from_raw_parts(input, length) };
    let target = input[0];
    if !(-512..=512).contains(&target) || input[1..].iter().any(|&x| !(-64..=64).contains(&x)) {
        return -1;
    }
    let items = length - 1;
    let mut masks = [0u8; 256];
    let mut count = 0usize;
    for mask in 0..(1usize << items) {
        let sum = input[1..].iter().enumerate()
            .filter(|(index, _)| (mask >> index) & 1 == 1)
            .map(|(_, value)| *value).sum::<i64>();
        if sum == target { masks[count] = mask as u8; count += 1; }
    }
    if output_capacity < count { return -2; }
    if count != 0 {
        if output.is_null() { return -2; }
        unsafe { std::ptr::copy_nonoverlapping(masks.as_ptr(), output, count); }
    }
    count as i64
}
