fn quick_sort_3_range(values: &mut [i64], mut low: usize, mut high: usize) {
    while high - low > 1 {
        let pivot = values[high - 1];
        let mut less = low;
        let mut scan = low;
        let mut greater = high;
        while scan < greater {
            if values[scan] < pivot {
                values.swap(less, scan);
                less += 1;
                scan += 1;
            } else if values[scan] > pivot {
                greater -= 1;
                values.swap(scan, greater);
            } else {
                scan += 1;
            }
        }
        if less - low < high - greater {
            quick_sort_3_range(values, low, less);
            low = greater;
        } else {
            quick_sort_3_range(values, greater, high);
            high = less;
        }
    }
}

/// In-place three-way quicksort using the final value as pivot.
#[no_mangle]
pub extern "C" fn quick_sort_3(values: *mut i64, length: usize) {
    if length < 2 {
        return;
    }
    let values = unsafe { std::slice::from_raw_parts_mut(values, length) };
    quick_sort_3_range(values, 0, length);
}
