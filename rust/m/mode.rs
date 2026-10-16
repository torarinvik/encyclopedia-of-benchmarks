/// Find the unique mode of a bounded array of small nonnegative integers.
#[no_mangle]
pub extern "C" fn mode(values: *const i64, length: usize) -> i64 {
    if values.is_null() || length == 0 || length > 4096 { return -1; }
    let values = unsafe { std::slice::from_raw_parts(values, length) };
    let mut counts = [0usize; 256];
    for &value in values {
        if !(0..=255).contains(&value) { return -1; }
        counts[value as usize] += 1;
    }
    let mut maximum = 0usize;
    let mut result = -1i64;
    let mut unique = true;
    for (value, &count) in counts.iter().enumerate() {
        if count > maximum {
            maximum = count;
            result = value as i64;
            unique = true;
        } else if count != 0 && count == maximum {
            unique = false;
        }
    }
    if unique { result } else { -1 }
}
