/// Sum a bounded array of nonnegative signed integers.
#[no_mangle]
pub extern "C" fn array_sum(values: *const i64, length: usize) -> i64 {
    if values.is_null() || length < 1 { return -1; }
    let input = unsafe { std::slice::from_raw_parts(values, length) };
    let count_value = input[0];
    if !(0..=1024).contains(&count_value) { return -1; }
    let count = count_value as usize;
    if length != count + 1 { return -1; }
    let mut sum = 0i64;
    for &value in &input[1..] {
        if !(0..=1_000_000_000).contains(&value) { return -1; }
        sum += value;
    }
    sum
}
