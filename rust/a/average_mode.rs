/// Return the unique mode of a bounded integer sequence.
#[no_mangle]
pub extern "C" fn average_mode(values: *const i64, length: usize) -> i64 {
    if values.is_null() || length == 0 || length > 64 { return -1; }
    let input = unsafe { std::slice::from_raw_parts(values, length) };
    if input.iter().any(|&value| !(0..=1000).contains(&value)) { return -1; }

    let mut mode = -1;
    let mut maximum_count = 0usize;
    let mut tied = false;
    for (i, &value) in input.iter().enumerate() {
        if input[..i].contains(&value) { continue; }
        let count = input.iter().filter(|&&candidate| candidate == value).count();
        if count > maximum_count {
            maximum_count = count;
            mode = value;
            tied = false;
        } else if count == maximum_count {
            tied = true;
        }
    }
    if tied { -1 } else { mode }
}
