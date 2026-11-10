/// Binary search the pair alignment around the unique value.
const MAX_VALUES: usize = 1025;
const INVALID_RESULT: i64 = -2_147_483_649;

#[no_mangle]
pub extern "C" fn single_non_duplicate(values: *const i64, length: usize) -> i64 {
    if length == 0 || length > MAX_VALUES || length % 2 == 0 {
        return INVALID_RESULT;
    }
    let mut left = 0usize;
    let mut right = length / 2;
    while left < right {
        let middle = left + (right - left) / 2;
        if unsafe { *values.add(middle * 2) == *values.add(middle * 2 + 1) } {
            left = middle + 1;
        } else {
            right = middle;
        }
    }
    unsafe { *values.add(left * 2) }
}
