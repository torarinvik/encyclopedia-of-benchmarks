fn shrink_gap(gap: usize) -> usize {
    (gap / 13) * 10 + ((gap % 13) * 10) / 13
}

/// Comb sort with a rational 10/13 gap shrink factor.
#[no_mangle]
pub extern "C" fn comb_sort(values: *mut i64, length: usize) {
    if length < 2 {
        return;
    }
    let values = unsafe { std::slice::from_raw_parts_mut(values, length) };
    let mut gap = length;
    let mut swapped = true;
    while gap > 1 || swapped {
        gap = shrink_gap(gap).max(1);
        swapped = false;
        for index in 0..(length - gap) {
            if values[index] > values[index + gap] {
                values.swap(index, index + gap);
                swapped = true;
            }
        }
    }
}
