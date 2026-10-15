/// Sort values and grow the longest affordable window.
#[no_mangle]
pub unsafe extern "C" fn maximum_frequency_after_increments(input: *const i64, length: usize) -> i64 {
    if length < 1 || length > 257 || input.is_null() { return -1; }
    let budget = *input;
    let count = length - 1;
    if !(0..=1_000_000).contains(&budget) { return -1; }
    let mut values = [0i64; 256];
    for index in 0..count {
        let value = *input.add(index + 1);
        if !(1..=10_000).contains(&value) { return -1; }
        let mut position = index;
        while position > 0 && values[position - 1] > value {
            values[position] = values[position - 1];
            position -= 1;
        }
        values[position] = value;
    }
    let mut left = 0usize;
    let mut window_sum = 0i64;
    let mut best = 0usize;
    for right in 0..count {
        window_sum += values[right];
        while values[right] * (right - left + 1) as i64 - window_sum > budget {
            window_sum -= values[left];
            left += 1;
        }
        best = best.max(right - left + 1);
    }
    best as i64
}
