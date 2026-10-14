/// Recursive circle sort for the shared signed 64-bit benchmark contract.
fn circle_pass(values: &mut [i64]) -> bool {
    let length = values.len();
    if length < 2 {
        return false;
    }
    let mut swapped = false;
    let mut left = 0;
    let mut right = length - 1;
    while left < right {
        if values[left] > values[right] {
            values.swap(left, right);
            swapped = true;
        }
        left += 1;
        right -= 1;
    }
    if length % 2 != 0 && left == right && right + 1 < length && values[right + 1] < values[right] {
        values.swap(right, right + 1);
        swapped = true;
    }
    let split = length / 2 + length % 2;
    let (left_values, right_values) = values.split_at_mut(split);
    let left_swapped = circle_pass(left_values);
    let right_swapped = circle_pass(right_values);
    swapped || left_swapped || right_swapped
}

fn circle_sort_range(values: &mut [i64]) {
    while values.len() > 1 && circle_pass(values) { }
}

#[no_mangle]
pub extern "C" fn circle_sort(values: *mut i64, length: usize) {
    if length < 2 {
        return;
    }
    let values = unsafe { std::slice::from_raw_parts_mut(values, length) };
    circle_sort_range(values);
}
