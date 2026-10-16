const MAX_ITEMS: i64 = 1024;
const INVALID_RESULT: i64 = -2;

fn search_range(values: &[i64], key: i64, left: i64, right: i64) -> i64 {
    if left > right { return -1; }
    if values[left as usize] == key { return left; }
    if values[right as usize] == key { return right; }
    search_range(values, key, left + 1, right - 1)
}

/// Search from both ends inward in the pinned source's left-then-right order.
#[no_mangle]
pub unsafe extern "C" fn double_linear_search_recursion(input: *const i64, length: usize) -> i64 {
    if input.is_null() || length < 2 || length > (MAX_ITEMS + 2) as usize { return INVALID_RESULT; }
    let values = unsafe { core::slice::from_raw_parts(input, length) };
    let count = values[0];
    let key = values[1];
    if !(0..=MAX_ITEMS).contains(&count) || !(i32::MIN as i64..=i32::MAX as i64).contains(&key) ||
        length != (2 + count) as usize { return INVALID_RESULT; }
    let items = &values[2..];
    if items.iter().any(|value| !(i32::MIN as i64..=i32::MAX as i64).contains(value)) {
        return INVALID_RESULT;
    }
    search_range(items, key, 0, count - 1)
}
