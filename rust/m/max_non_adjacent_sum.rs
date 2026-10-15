/// Return the maximum sum of non-adjacent values, allowing an empty selection.
#[no_mangle]
pub extern "C" fn max_non_adjacent_sum(values: *const i64, length: usize) -> i64 {
    const INVALID: i64 = i64::MIN;
    if values.is_null() || !(1..=100000).contains(&length) {
        return INVALID;
    }
    let values = unsafe { std::slice::from_raw_parts(values, length) };
    let mut two_back = 0i64;
    let mut one_back = 0i64;
    for &value in values {
        if !(0..=10000).contains(&value) {
            return INVALID;
        }
        let take = two_back + value;
        let current = take.max(one_back);
        two_back = one_back;
        one_back = current;
    }
    one_back
}
