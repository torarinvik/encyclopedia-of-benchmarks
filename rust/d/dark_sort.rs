/// Dark sort: counting sort for nonnegative keys in [0, 128].
#[no_mangle]
pub extern "C" fn dark_sort(values: *mut i64, length: usize) {
    if length < 2 { return; }
    let values = unsafe { std::slice::from_raw_parts_mut(values, length) };
    let maximum = *values.iter().max().unwrap() as usize;
    let mut counts = [0i64; 129];
    for &value in values.iter() { counts[value as usize] += 1; }
    let mut output = 0;
    for (value, count) in counts.iter_mut().enumerate().take(maximum + 1) {
        while *count > 0 {
            values[output] = value as i64;
            output += 1;
            *count -= 1;
        }
    }
}
