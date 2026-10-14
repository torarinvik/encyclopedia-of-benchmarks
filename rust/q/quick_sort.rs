fn partition(values: &mut [i64], low: usize, high: usize) -> usize {
    let pivot = values[high - 1];
    let mut boundary = low;
    for scan in low..(high - 1) {
        if values[scan] <= pivot {
            values.swap(boundary, scan);
            boundary += 1;
        }
    }
    values.swap(boundary, high - 1);
    boundary
}

fn quick_sort_range(values: &mut [i64], mut low: usize, mut high: usize) {
    while high - low > 1 {
        let pivot = partition(values, low, high);
        let right_start = pivot + 1;
        if pivot - low < high - right_start {
            quick_sort_range(values, low, pivot);
            low = right_start;
        } else {
            quick_sort_range(values, right_start, high);
            high = pivot;
        }
    }
}

/// Lomuto quicksort; recurse into the smaller partition to bound stack depth.
#[no_mangle]
pub extern "C" fn quick_sort(values: *mut i64, length: usize) {
    if length < 2 {
        return;
    }
    let values = unsafe { std::slice::from_raw_parts_mut(values, length) };
    quick_sort_range(values, 0, length);
}
