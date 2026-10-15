fn simple_binary_search_range(values: &[i64], low: usize, high: usize, target: i64) -> i64 {
    if low >= high {
        return 0;
    }

    let middle = low + (high - low) / 2;
    if values[middle] == target {
        return 1;
    }
    if target < values[middle] {
        return simple_binary_search_range(values, low, middle, target);
    }
    simple_binary_search_range(values, middle + 1, high, target)
}

/// Recursive binary search membership check over an ascending sequence.
#[no_mangle]
pub extern "C" fn simple_binary_search(values: *const i64, length: usize, target: i64) -> i64 {
    let values = if length == 0 {
        &[]
    } else {
        unsafe { std::slice::from_raw_parts(values, length) }
    };
    simple_binary_search_range(values, 0, length, target)
}
