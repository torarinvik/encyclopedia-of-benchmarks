fn quick_sort_iterative_partition(values: &mut [i64], low: usize, high: usize) -> usize {
    let pivot = values[high - 1];
    let mut boundary = low;
    for scan in low..high - 1 {
        if values[scan] <= pivot {
            values.swap(boundary, scan);
            boundary += 1;
        }
    }
    values.swap(boundary, high - 1);
    boundary
}

/// Iterative Lomuto quicksort using the final value as the pivot.
#[no_mangle]
pub extern "C" fn quick_sort_iterative(values: *mut i64, length: usize) {
    if length < 2 {
        return;
    }
    let values = unsafe { std::slice::from_raw_parts_mut(values, length) };
    let mut stack_low = [0usize; 128];
    let mut stack_high = [0usize; 128];
    let mut stack_size = 0usize;
    let mut low = 0usize;
    let mut high = length;

    loop {
        while high - low > 1 {
            let pivot = quick_sort_iterative_partition(values, low, high);
            let left_size = pivot - low;
            let right_size = high - pivot - 1;
            if left_size < right_size {
                if right_size > 1 {
                    stack_low[stack_size] = pivot + 1;
                    stack_high[stack_size] = high;
                    stack_size += 1;
                }
                high = pivot;
            } else {
                if left_size > 1 {
                    stack_low[stack_size] = low;
                    stack_high[stack_size] = pivot;
                    stack_size += 1;
                }
                low = pivot + 1;
            }
        }
        if stack_size == 0 {
            break;
        }
        stack_size -= 1;
        low = stack_low[stack_size];
        high = stack_high[stack_size];
    }
}
