/// Count positions where the prefix sum is at least the remaining suffix sum.
const MAX_LENGTH: usize = 100_000;
const MAX_VALUE: i64 = 100_000;

#[no_mangle]
pub extern "C" fn ways_to_split_array(values: *const i64, length: usize) -> i64 {
    if values.is_null() || length < 2 || length > MAX_LENGTH { return -1; }
    let input = unsafe { std::slice::from_raw_parts(values, length) };
    let mut total = 0u64;
    let mut largest_biased_value = 0u64;
    for &value in input {
        let value = value as u64;
        largest_biased_value = largest_biased_value.max(value.wrapping_add(MAX_VALUE as u64));
        total = total.wrapping_add(value);
    }
    if largest_biased_value > 2 * MAX_VALUE as u64 { return -1; }
    let threshold = (total.wrapping_add(1) as i64) >> 1;
    let mut prefix = 0u64;
    let mut ways = 0i64;
    for &value in &input[..length - 1] {
        prefix = prefix.wrapping_add(value as u64);
        if prefix as i64 >= threshold { ways += 1; }
    }
    ways
}
