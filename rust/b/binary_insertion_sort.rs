/// Stable binary insertion sort using an upper-bound search for each key.
#[no_mangle]
pub extern "C" fn binary_insertion_sort(values: *mut i64, length: usize) {
    if length < 2 {
        return;
    }
    let values = unsafe { std::slice::from_raw_parts_mut(values, length) };
    for index in 1..length {
        let key = values[index];
        let mut low = 0;
        let mut high = index;
        while low < high {
            let middle = low + (high - low) / 2;
            if values[middle] <= key {
                low = middle + 1;
            } else {
                high = middle;
            }
        }
        let mut position = index;
        while position > low {
            values[position] = values[position - 1];
            position -= 1;
        }
        values[low] = key;
    }
}
