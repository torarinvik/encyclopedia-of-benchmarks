/// Bead sort for the benchmark's nonnegative 0..63 domain.
#[no_mangle]
pub extern "C" fn bead_sort(values: *mut i64, scratch: *mut i64, length: usize) {
    if length < 2 {
        return;
    }
    let values = unsafe { std::slice::from_raw_parts_mut(values, length) };
    let scratch = unsafe { std::slice::from_raw_parts_mut(scratch, 64) };
    scratch.fill(0);
    for &value in values.iter() {
        for level in 0..value as usize {
            scratch[level] += 1;
        }
    }
    for index in 0..length {
        let row_from_bottom = length - 1 - index;
        let mut value = 0i64;
        for level in 0..64 {
            if scratch[level] > row_from_bottom as i64 {
                value += 1;
            }
        }
        values[index] = value;
    }
}
