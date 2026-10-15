fn dual_pivot_sort_range(values: &mut [i64], mut low: usize, mut high: usize) {
    while high - low > 2 {
        if values[low] > values[high - 1] {
            values.swap(low, high - 1);
        }
        let pivot1 = values[low];
        let pivot2 = values[high - 1];
        let mut less = low + 1;
        let mut scan = low + 1;
        let mut greater = high - 2;
        while scan <= greater {
            if values[scan] < pivot1 {
                values.swap(scan, less);
                less += 1;
            } else if values[scan] >= pivot2 {
                while scan < greater && values[greater] > pivot2 {
                    greater -= 1;
                }
                values.swap(scan, greater);
                greater -= 1;
                if values[scan] < pivot1 {
                    values.swap(scan, less);
                    less += 1;
                }
            }
            scan += 1;
        }
        let pivot1_index = less - 1;
        let pivot2_index = greater + 1;
        values.swap(low, pivot1_index);
        values.swap(high - 1, pivot2_index);
        let left_size = pivot1_index - low;
        let middle_size = pivot2_index - pivot1_index - 1;
        let right_size = high - pivot2_index - 1;
        if left_size >= middle_size && left_size >= right_size {
            dual_pivot_sort_range(values, pivot1_index + 1, pivot2_index);
            dual_pivot_sort_range(values, pivot2_index + 1, high);
            high = pivot1_index;
        } else if middle_size >= right_size {
            dual_pivot_sort_range(values, low, pivot1_index);
            dual_pivot_sort_range(values, pivot2_index + 1, high);
            low = pivot1_index + 1;
            high = pivot2_index;
        } else {
            dual_pivot_sort_range(values, low, pivot1_index);
            dual_pivot_sort_range(values, pivot1_index + 1, pivot2_index);
            low = pivot2_index + 1;
        }
    }
    if high - low == 2 && values[low] > values[low + 1] {
        values.swap(low, low + 1);
    }
}

/// In-place dual-pivot quicksort using the first and final values as pivots.
#[no_mangle]
pub extern "C" fn dual_pivot_quick_sort(values: *mut i64, length: usize) {
    if length < 2 {
        return;
    }
    let values = unsafe { std::slice::from_raw_parts_mut(values, length) };
    dual_pivot_sort_range(values, 0, length);
}
