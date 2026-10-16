fn bst_shape(start: usize, end: usize, heap_index: usize) -> u64 {
    if start >= end { return 0; }
    let middle = start + (end - start - 1) / 2;
    (1_u64 << heap_index)
        | bst_shape(start, middle, 2 * heap_index + 1)
        | bst_shape(middle + 1, end, 2 * heap_index + 2)
}

#[no_mangle]
pub unsafe extern "C" fn bst_from_sorted_array(values: *const i64, length: usize) -> i64 {
    if length > 15 || (length != 0 && values.is_null()) { return -1; }
    for index in 0..length {
        let value = *values.add(index);
        if value < i32::MIN as i64 || value > i32::MAX as i64 { return -1; }
        if index > 0 && *values.add(index - 1) >= value { return -1; }
    }
    bst_shape(0, length, 0) as i64
}
