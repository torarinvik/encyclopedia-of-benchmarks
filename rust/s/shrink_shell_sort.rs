/// Shell sort using the pinned Python 1.3 gap shrink factor.
#[no_mangle]
pub extern "C" fn shrink_shell_sort(values: *mut i64, length: usize) {
    if length < 2 { return; }
    let values = unsafe { std::slice::from_raw_parts_mut(values, length) };
    let mut gap = length;
    while gap > 1 {
        gap = (gap as f64 / 1.3) as usize;
        for index in gap..length {
            let key = values[index];
            let mut position = index;
            while position >= gap && values[position - gap] > key {
                values[position] = values[position - gap];
                position -= gap;
            }
            values[position] = key;
        }
    }
}
