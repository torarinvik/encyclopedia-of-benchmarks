/// Binary search the pair alignment around the unique value.
const MAX_VALUES: usize = 1025;
const INVALID_RESULT: i64 = -2_147_483_649;

#[no_mangle]
pub extern "C" fn single_non_duplicate(values: *const i64, length: usize) -> i64 {
    if values.is_null() || length == 0 || length > MAX_VALUES || length % 2 == 0 {
        return INVALID_RESULT;
    }
    let mut left = 0usize;
    let mut right = length - 1;
    while left < right {
        let middle = left + (right - left) / 2;
        if middle % 2 == 0 {
            if unsafe { *values.add(middle) == *values.add(middle + 1) } { left = middle + 2; }
            else { right = middle; }
        } else {
            if unsafe { *values.add(middle) == *values.add(middle - 1) } { left = middle + 1; }
            else { right = middle - 1; }
        }
    }
    unsafe { *values.add(left) }
}
