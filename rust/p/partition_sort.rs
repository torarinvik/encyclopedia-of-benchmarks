fn partition_range(values: &mut [i64], low: usize, high: usize) -> usize {
    let pivot = values[low];
    let mut left = low;
    let mut right = high;
    loop {
        while values[left] < pivot { left += 1; }
        while values[right] > pivot { right -= 1; }
        if left >= right { return right; }
        values.swap(left, right);
        left += 1;
        right -= 1;
    }
}

fn partition_sort_range(values: &mut [i64], low: usize, high: usize) {
    if low < high {
        let split = partition_range(values, low, high);
        partition_sort_range(values, low, split);
        partition_sort_range(values, split + 1, high);
    }
}

/// First-element-pivot quicksort using Hoare's partition scheme.
#[no_mangle]
pub extern "C" fn partition_sort(values: *mut i64, length: usize) {
    if length < 2 { return; }
    let values = unsafe { std::slice::from_raw_parts_mut(values, length) };
    partition_sort_range(values, 0, length - 1);
}
