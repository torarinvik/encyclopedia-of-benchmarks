#[no_mangle]
pub unsafe extern "C" fn two_pointers_pair_exists(input: *const i64, length: usize) -> i64 {
    if input.is_null() || length < 2 || length > 258 { return -1; }
    let values = unsafe { std::slice::from_raw_parts(input, length) };
    let target = values[0];
    let n = values[1];
    if n < 0 || n > 256 || length != 2 + n as usize || !(-2_000_000..=2_000_000).contains(&target) { return -1; }
    let array = &values[2..];
    if array.iter().any(|&v| !(-1_000_000..=1_000_000).contains(&v))
        || array.windows(2).any(|pair| pair[0] > pair[1]) { return -1; }
    if n < 2 { return 0; }
    let (mut left, mut right) = (0usize, array.len() - 1);
    while left < right {
        let sum = array[left] + array[right];
        if sum == target { return 1; }
        if sum < target { left += 1; } else { right -= 1; }
    }
    0
}
