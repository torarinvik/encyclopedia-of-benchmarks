fn bitonic_compare(values: &mut [i64], left: usize, right: usize, ascending: bool) {
    if (ascending && values[left] > values[right]) || (!ascending && values[left] < values[right]) {
        values.swap(left, right);
    }
}

fn bitonic_merge(values: &mut [i64], low: usize, length: usize, ascending: bool) {
    if length < 2 {
        return;
    }
    let half = length / 2;
    for index in low..(low + half) {
        bitonic_compare(values, index, index + half, ascending);
    }
    bitonic_merge(values, low, half, ascending);
    bitonic_merge(values, low + half, half, ascending);
}

fn bitonic_sort_range(values: &mut [i64], low: usize, length: usize, ascending: bool) {
    if length < 2 {
        return;
    }
    let half = length / 2;
    bitonic_sort_range(values, low, half, true);
    bitonic_sort_range(values, low + half, half, false);
    bitonic_merge(values, low, length, ascending);
}

/// Portable bitonic sorting network for power-of-two lengths.
#[no_mangle]
pub extern "C" fn bitonic_sort(values: *mut i64, length: usize) {
    if length < 2 {
        return;
    }
    let values = unsafe { std::slice::from_raw_parts_mut(values, length) };
    bitonic_sort_range(values, 0, length, true);
}
