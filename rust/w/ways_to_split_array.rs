/// Count positions where the prefix sum is at least the remaining suffix sum.
const MAX_LENGTH: usize = 100_000;
const MAX_VALUE: i64 = 100_000;

#[no_mangle]
pub extern "C" fn ways_to_split_array(values: *const i64, length: usize) -> i64 {
    if values.is_null() || length < 2 || length > MAX_LENGTH { return -1; }
    let input = unsafe { std::slice::from_raw_parts(values, length) };
    if input.iter().any(|&value| !(-MAX_VALUE..=MAX_VALUE).contains(&value)) { return -1; }
    let total_sum: i64 = input.iter().sum();
    let mut prefix_sum = 0i64;
    let mut ways = 0i64;
    for &value in &input[..length - 1] {
        prefix_sum += value;
        if prefix_sum >= total_sum - prefix_sum { ways += 1; }
    }
    ways
}
