fn recursive_binary_search_range(values: &[i64], low: usize, high: usize, target: i64) -> i64 {
    if low >= high {
        return -1;
    }

    let middle = low + (high - low) / 2;
    if values[middle] == target {
        return middle as i64;
    }
    if target < values[middle] {
        return recursive_binary_search_range(values, low, middle, target);
    }
    recursive_binary_search_range(values, middle + 1, high, target)
}

/// Recursive binary search for the shared C ABI benchmark contract.
#[no_mangle]
pub extern "C" fn recursive_binary_search(values: *const i64, length: usize, target: i64) -> i64 {
    let values = if length == 0 {
        &[]
    } else {
        unsafe { std::slice::from_raw_parts(values, length) }
    };
    recursive_binary_search_range(values, 0, length, target)
}
