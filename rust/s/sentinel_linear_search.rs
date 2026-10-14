/// Sentinel linear search for the shared mutable-input benchmark contract.
#[no_mangle]
pub extern "C" fn sentinel_linear_search(values: *mut i64, length: usize, target: i64) -> i64 {
    if length == 0 {
        return -1;
    }

    unsafe {
        let last_index = length - 1;
        let last = values.add(last_index);
        let saved_last = *last;
        if saved_last == target {
            return last_index as i64;
        }

        *last = target;
        let mut index = 0usize;
        while *values.add(index) != target {
            index += 1;
        }
        *last = saved_last;

        if index == last_index {
            -1
        } else {
            index as i64
        }
    }
}
