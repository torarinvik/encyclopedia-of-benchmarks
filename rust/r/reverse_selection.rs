/// Selection sort variant that reverses the selected prefix to place its minimum.
#[no_mangle]
pub extern "C" fn reverse_selection(values: *mut i64, length: usize) {
    if length < 2 {
        return;
    }
    let values = unsafe { std::slice::from_raw_parts_mut(values, length) };
    for start in 0..length - 1 {
        let mut minimum = start;
        for scan in start + 1..length {
            if values[scan] < values[minimum] {
                minimum = scan;
            }
        }
        let mut left = start;
        let mut right = minimum;
        while left < right {
            values.swap(left, right);
            left += 1;
            right -= 1;
        }
    }
}
