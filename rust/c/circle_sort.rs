fn circle_sort_range(values: &mut [i64], left_value: usize, right_value: usize) -> bool {
    if left_value >= right_value {
        return false;
    }

    let mut low = left_value;
    let mut high = right_value;
    let mut swapped = false;
    while low < high {
        if values[low] > values[high] {
            values.swap(low, high);
            swapped = true;
        }
        low += 1;
        high -= 1;
    }
    if low == high && values[low] > values[high + 1] {
        values.swap(low, high + 1);
        swapped = true;
    }

    let middle = left_value + (right_value - left_value) / 2;
    let left_swapped = circle_sort_range(values, left_value, middle);
    let right_swapped = circle_sort_range(values, middle + 1, right_value);
    swapped || left_swapped || right_swapped
}

/// Recursively compares mirrored pairs until each pass makes no swaps.
#[no_mangle]
pub extern "C" fn circle_sort(values: *mut i64, length: usize) {
    if length < 2 {
        return;
    }
    let values = unsafe { std::slice::from_raw_parts_mut(values, length) };
    while circle_sort_range(values, 0, length - 1) {}
}
