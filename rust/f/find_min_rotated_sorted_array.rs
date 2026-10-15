/// Return the minimum in a rotation of a strictly increasing i64 array.
#[no_mangle]
pub unsafe extern "C" fn find_min_rotated_sorted_array(values: *const i64, length: usize) -> i64 {
    if length < 1 || length > 256 || values.is_null() { return -1; }
    let mut low = 0usize;
    let mut high = length - 1;
    while low < high {
        let middle = low + (high - low) / 2;
        if *values.add(middle) <= *values.add(high) { high = middle; }
        else { low = middle + 1; }
    }
    *values.add(low)
}
