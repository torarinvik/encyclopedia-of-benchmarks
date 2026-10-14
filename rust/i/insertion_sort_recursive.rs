/// Stable recursive insertion sort over signed 64-bit values.
unsafe fn insertion_sort_prefix(values: *mut i64, length: usize) {
    if length <= 1 { return; }
    insertion_sort_prefix(values, length - 1);
    let key = *values.add(length - 1);
    let mut position = length - 1;
    while position > 0 && *values.add(position - 1) > key {
        *values.add(position) = *values.add(position - 1);
        position -= 1;
    }
    *values.add(position) = key;
}

#[no_mangle]
pub unsafe extern "C" fn insertion_sort_recursive(values: *mut i64, length: usize) {
    insertion_sort_prefix(values, length);
}
