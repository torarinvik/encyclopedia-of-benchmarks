/// Find the peak of a strict mountain array with binary search.
const MAX_ARRAY_LENGTH: usize = 100000;

#[no_mangle]
pub unsafe extern "C" fn peak_index_in_mountain_array(values: *const i64,
                                                      length: usize) -> i64 {
    if values.is_null() || length < 3 || length > MAX_ARRAY_LENGTH { return -1; }
    let mut low = 0usize;
    let mut high = length - 1;
    while low < high {
        let middle = low + (high - low) / 2;
        if *values.add(middle) < *values.add(middle + 1) { low = middle + 1; }
        else { high = middle; }
    }
    if low == 0 || low + 1 == length { return -1; }
    low as i64
}
