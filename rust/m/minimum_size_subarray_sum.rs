#[no_mangle]
pub extern "C" fn minimum_size_subarray_sum(packed: *const i64, length: usize) -> i64 {
    if packed.is_null() || length < 2 {
        return -1;
    }
    let values = unsafe { std::slice::from_raw_parts(packed, length) };
    let target = values[0];
    let count = values[1];
    if !(1..=1_000_000).contains(&target)
        || !(0..=256).contains(&count)
        || length != count as usize + 2
    {
        return -1;
    }
    let values = &values[2..];
    if values.iter().any(|&value| !(1..=1_000_000).contains(&value)) {
        return -1;
    }
    let mut left = 0usize;
    let mut current_sum = 0i64;
    let mut best = values.len() + 1;
    for right in 0..values.len() {
        current_sum += values[right];
        while current_sum >= target {
            best = best.min(right - left + 1);
            current_sum -= values[left];
            left += 1;
        }
    }
    if best <= values.len() { best as i64 } else { 0 }
}
