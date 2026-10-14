/// Stable insertion sort for the shared mutable in-place sorting contract.
#[no_mangle]
pub extern "C" fn insertion_sort(values: *mut i64, length: usize) {
    if length < 2 {
        return;
    }
    let values = unsafe { std::slice::from_raw_parts_mut(values, length) };
    for index in 1..length {
        let key = values[index];
        let mut position = index;
        while position > 0 && values[position - 1] > key {
            values[position] = values[position - 1];
            position -= 1;
        }
        values[position] = key;
    }
}
