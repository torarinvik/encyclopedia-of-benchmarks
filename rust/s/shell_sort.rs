/// Shell sort with a halving gap sequence for the shared contract.
#[no_mangle]
pub extern "C" fn shell_sort(values: *mut i64, length: usize) {
    if length < 2 {
        return;
    }
    let values = unsafe { std::slice::from_raw_parts_mut(values, length) };
    let mut gap = length / 2;
    while gap > 0 {
        for index in gap..length {
            let key = values[index];
            let mut position = index;
            while position >= gap && values[position - gap] > key {
                values[position] = values[position - gap];
                position -= gap;
            }
            values[position] = key;
        }
        gap /= 2;
    }
}
