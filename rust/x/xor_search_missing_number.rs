const MAX_N: i64 = 255;
const MAX_INPUT_LENGTH: usize = 257;

#[no_mangle]
pub unsafe extern "C" fn xor_search_missing_number(input: *const i64, length: usize) -> i64 {
    if input.is_null() || length < 1 || length > MAX_INPUT_LENGTH { return -1; }
    let values = std::slice::from_raw_parts(input, length);
    let n_value = values[0];
    if n_value < 0 || n_value > MAX_N || length != n_value as usize + 1 { return -1; }
    let n = n_value as usize;
    let mut seen = [false; 256];
    let mut result = n_value;
    for (i, &value) in values[1..].iter().enumerate() {
        if value < 0 || value > n_value || seen[value as usize] { return -1; }
        seen[value as usize] = true;
        result ^= i as i64 ^ value;
    }
    result
}
