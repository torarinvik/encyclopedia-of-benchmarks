/// Minimum deletions to leave all a values before all b values.
#[no_mangle]
pub extern "C" fn minimum_deletions_to_make_string_balanced(values: *const i64, length: usize) -> i64 {
    if length > 256 {
        return -1;
    }
    if length == 0 {
        return 0;
    }
    let values = unsafe { std::slice::from_raw_parts(values, length) };
    let mut a_state = 0i64;
    let mut b_state = 0i64;
    for &value in values {
        if !(0..=1).contains(&value) {
            return -1;
        }
        b_state += i64::from(value == 0 && b_state < a_state);
        a_state += value;
    }
    b_state
}
