/// Backward recursive linear search over a bounded integer array.
fn search_from_end(items: &[i64], target: i64) -> i64 {
    let Some((&last, prefix)) = items.split_last() else { return -1; };
    if last == target { return prefix.len() as i64; }
    search_from_end(prefix, target)
}

#[no_mangle]
pub unsafe extern "C" fn recursive_linear_search(values: *const i64, length: usize) -> i64 {
    if values.is_null() || length < 2 || length > 67 { return -1; }
    let count_value = *values;
    let target = *values.add(1);
    if !(1..=64).contains(&count_value) { return -1; }
    let count = count_value as usize;
    if length != count + 2 { return -1; }
    let items = std::slice::from_raw_parts(values.add(2), count);
    search_from_end(items, target)
}
