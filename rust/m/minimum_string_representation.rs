/// Least cyclic rotation by two-candidate elimination.
#[no_mangle]
pub extern "C" fn minimum_string_representation(values: *const i64, length: usize) -> i64 {
    if length > 4096 { return -1; }
    if length == 0 { return 0; }
    if values.is_null() { return -1; }
    let values = unsafe { std::slice::from_raw_parts(values, length) };
    if values.iter().any(|&value| !(0..=127).contains(&value)) { return -1; }

    let mut left = 0_usize;
    let mut right = 1_usize;
    let mut matched = 0_usize;
    while left < length && right < length && matched < length {
        let a = values[(left + matched) % length];
        let b = values[(right + matched) % length];
        if a == b {
            matched += 1;
            continue;
        }
        if a > b {
            left += matched + 1;
            if left == right { left += 1; }
        } else {
            right += matched + 1;
            if left == right { right += 1; }
        }
        matched = 0;
    }
    left.min(right) as i64
}
