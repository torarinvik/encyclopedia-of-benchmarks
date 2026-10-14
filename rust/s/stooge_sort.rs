fn stooge_sort_range(values: &mut [i64], low: usize, high: usize) {
    let length = high - low;
    if length < 2 {
        return;
    }
    if values[low] > values[high - 1] {
        values.swap(low, high - 1);
    }
    if length > 2 {
        let third = length / 3;
        stooge_sort_range(values, low, high - third);
        stooge_sort_range(values, low + third, high);
        stooge_sort_range(values, low, high - third);
    }
}

/// Stooge sort using half-open ranges.
#[no_mangle]
pub extern "C" fn stooge_sort(values: *mut i64, length: usize) {
    if length < 2 {
        return;
    }
    let values = unsafe { std::slice::from_raw_parts_mut(values, length) };
    stooge_sort_range(values, 0, length);
}
