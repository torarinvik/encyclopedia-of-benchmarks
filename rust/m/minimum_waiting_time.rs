/// Schedule shortest queries first and sum each query's time spent waiting.
#[no_mangle]
pub extern "C" fn minimum_waiting_time(values: *const i64, length: usize) -> i64 {
    if length > 64 {
        return i64::MIN;
    }
    if length == 0 {
        return 0;
    }
    if values.is_null() {
        return i64::MIN;
    }
    let input = unsafe { std::slice::from_raw_parts(values, length) };
    let mut durations = [0i64; 64];
    for (index, &value) in input.iter().enumerate() {
        if !(0..=1000).contains(&value) {
            return i64::MIN;
        }
        durations[index] = value;
    }
    for index in 1..length {
        let key = durations[index];
        let mut cursor = index;
        while cursor > 0 && durations[cursor - 1] > key {
            durations[cursor] = durations[cursor - 1];
            cursor -= 1;
        }
        durations[cursor] = key;
    }
    let mut total = 0i64;
    for index in 0..length {
        total += durations[index] * (length - index - 1) as i64;
    }
    total
}
