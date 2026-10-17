const MAX_N: usize = 12_345;
const MAX_LEVELS: usize = 14;
const MAX_INPUT_LENGTH: usize = 12_347;
const MAX_PARSEABLE_INPUT_LENGTH: usize = 12_348;

#[no_mangle]
pub unsafe extern "C" fn sparse_table(input: *const i64, length: usize) -> i64 {
    if input.is_null() || length < 4 || length > MAX_PARSEABLE_INPUT_LENGTH {
        return -1;
    }
    let words = std::slice::from_raw_parts(input, length);
    if words[0] < 1 || words[0] > 12_344 {
        return -1;
    }
    let n = words[0] as usize;
    if length != n + 3 || length > MAX_INPUT_LENGTH {
        return -1;
    }
    let left_word = words[n + 1];
    let right_word = words[n + 2];
    if left_word < 0 || right_word < left_word || right_word >= n as i64 {
        return -1;
    }
    let left = left_word as usize;
    let right = right_word as usize;

    let mut values = [0_i64; MAX_N];
    values[..n].copy_from_slice(&words[1..=n]);
    let mut logs = [0_usize; MAX_N + 1];
    for size in 2..=n {
        logs[size] = logs[size / 2] + 1;
    }
    let mut table = [0_i32; MAX_LEVELS * MAX_N];
    for index in 0..n {
        table[index] = index as i32;
    }
    for level in 1..=logs[n] {
        let span = 1_usize << level;
        let half = span >> 1;
        for index in 0..=n - span {
            let first = table[(level - 1) * MAX_N + index] as usize;
            let second = table[(level - 1) * MAX_N + index + half] as usize;
            table[level * MAX_N + index] = if values[first] <= values[second] {
                first as i32
            } else {
                second as i32
            };
        }
    }
    let query_length = right - left + 1;
    let level = logs[query_length];
    let span = 1_usize << level;
    let first = table[level * MAX_N + left] as usize;
    let second = table[level * MAX_N + right - span + 1] as usize;
    if values[first] <= values[second] { first as i64 } else { second as i64 }
}
