const MAX_CAPACITY: usize = 64;
const MAX_COUNT: usize = 256;
const MAX_VALID_INPUT_LENGTH: usize = 258;
const MAX_PARSEABLE_INPUT_LENGTH: usize = 259;
const INVALID_RESULT: i64 = i64::MIN;

#[no_mangle]
pub unsafe extern "C" fn sliding_window_aggregator(input: *const i64, length: usize) -> i64 {
    if input.is_null() || length < 2 || length > MAX_PARSEABLE_INPUT_LENGTH { return INVALID_RESULT; }
    let values = std::slice::from_raw_parts(input, length);
    if values[0] < 1 || values[0] > MAX_CAPACITY as i64 || values[1] < 1 || values[1] > MAX_COUNT as i64 { return INVALID_RESULT; }
    let capacity = values[0] as usize;
    let count = values[1] as usize;
    if length != count + 2 || length > MAX_VALID_INPUT_LENGTH { return INVALID_RESULT; }

    let mut window = [0_i64; MAX_CAPACITY];
    let mut head = 0_usize;
    let mut size = 0_usize;
    let mut sum = 0_i64;
    for &value in &values[2..] {
        if !(-1_000_000..=1_000_000).contains(&value) { return INVALID_RESULT; }
        if size < capacity {
            let position = (head + size) % capacity;
            window[position] = value;
            size += 1;
            sum += value;
        } else {
            sum -= window[head];
            window[head] = value;
            sum += value;
            head = (head + 1) % capacity;
        }
    }
    sum
}
