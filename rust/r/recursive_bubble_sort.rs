/// Recursive bubble sort for the shared signed 64-bit benchmark contract.
fn recursive_bubble_sort_range(values: &mut [i64]) {
    if values.len() < 2 {
        return;
    }
    for index in 0..values.len() - 1 {
        if values[index] > values[index + 1] {
            values.swap(index, index + 1);
        }
    }
    let active = values.len() - 1;
    recursive_bubble_sort_range(&mut values[..active]);
}

#[no_mangle]
pub extern "C" fn recursive_bubble_sort(values: *mut i64, length: usize) {
    if length < 2 {
        return;
    }
    let values = unsafe { std::slice::from_raw_parts_mut(values, length) };
    recursive_bubble_sort_range(values);
}
