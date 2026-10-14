/// Recursive selection sort for the shared signed 64-bit benchmark contract.
fn minimum_index(values: &[i64]) -> usize {
    if values.len() <= 1 {
        return 0;
    }
    let minimum = minimum_index(&values[1..]) + 1;
    if values[0] < values[minimum] { 0 } else { minimum }
}

fn selection_sort_range(values: &mut [i64]) {
    if values.len() <= 1 {
        return;
    }
    let minimum = minimum_index(values);
    values.swap(0, minimum);
    selection_sort_range(&mut values[1..]);
}

#[no_mangle]
pub extern "C" fn selection_sort_recursive(values: *mut i64, length: usize) {
    if length < 2 {
        return;
    }
    let values = unsafe { std::slice::from_raw_parts_mut(values, length) };
    selection_sort_range(values);
}
