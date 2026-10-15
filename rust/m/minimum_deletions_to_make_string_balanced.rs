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
        let next_a = a_state + if value == 1 { 1 } else { 0 };
        let b_with_a = b_state + if value == 0 { 1 } else { 0 };
        let next_b = a_state.min(b_with_a);
        a_state = next_a;
        b_state = next_b;
    }
    a_state.min(b_state)
}
