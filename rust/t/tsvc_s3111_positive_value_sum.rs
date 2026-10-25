const MAX_N: usize = 64;
const MAX_INPUT_LENGTH: usize = 1 + MAX_N;
const MAX_VALUE: i64 = 1_000_000;

#[no_mangle]
pub unsafe extern "C" fn tsvc_s3111_positive_value_sum(input: *const i64, length: usize) -> i64 {
    if input.is_null() || length < 1 || length > MAX_INPUT_LENGTH { return -1; }
    let values = std::slice::from_raw_parts(input, length);
    let n_raw = values[0];
    if n_raw < 0 || n_raw > MAX_N as i64 { return -1; }
    let n = n_raw as usize;
    if length != 1 + n { return -1; }

    let mut sum = 0i64;
    for &value in &values[1..] {
        if !(-MAX_VALUE..=MAX_VALUE).contains(&value) { return -1; }
        if value > 0 { sum += value; }
    }
    sum
}
