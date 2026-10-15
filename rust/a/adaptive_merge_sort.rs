const MAX_VALUES: usize = 1024;

unsafe fn merge_range(values: *mut i64, scratch: *mut i64, low: usize, high: usize) {
    if high - low <= 1 { return }
    let middle = low + (high - low) / 2;
    merge_range(values, scratch, low, middle);
    merge_range(values, scratch, middle, high);
    if *values.add(middle - 1) <= *values.add(middle) { return; }
    let mut left = low;
    let mut right = middle;
    let mut output = low;
    while left < middle && right < high {
        if *values.add(left) <= *values.add(right) {
            *scratch.add(output) = *values.add(left);
            left += 1;
        } else {
            *scratch.add(output) = *values.add(right);
            right += 1;
        }
        output += 1;
    }
    while left < middle { *scratch.add(output) = *values.add(left); left += 1; output += 1; }
    while right < high { *scratch.add(output) = *values.add(right); right += 1; output += 1; }
    for index in low..high { *values.add(index) = *scratch.add(index); }
}

#[no_mangle]
pub unsafe extern "C" fn adaptive_merge_sort(values: *mut i64, length: usize) {
    if length > MAX_VALUES { return }
    let mut scratch = [0_i64; MAX_VALUES];
    merge_range(values, scratch.as_mut_ptr(), 0, length);
}
