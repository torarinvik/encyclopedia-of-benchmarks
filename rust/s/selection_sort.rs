/// In-place selection sort for the shared sorting contract.
#[no_mangle]
pub extern "C" fn selection_sort(values: *mut i64, length: usize) {
    if length < 2 {
        return;
    }
    let values = unsafe { std::slice::from_raw_parts_mut(values, length) };
    for index in 0..(length - 1) {
        let mut minimum = index;
        for probe in index + 1..length {
            if values[probe] < values[minimum] {
                minimum = probe;
            }
        }
        if minimum != index {
            values.swap(index, minimum);
        }
    }
}
