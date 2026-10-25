const MAX_N: usize = 64;
const MAX_INPUT_LENGTH: usize = 1 + 3 * MAX_N;
const MAX_VALUE: i64 = 1_000_000;

#[no_mangle]
pub unsafe extern "C" fn tsvc_s4115_indexed_gather_product_sum(input: *const i64, length: usize) -> i64 {
    if input.is_null() || length < 4 || length > MAX_INPUT_LENGTH { return -1; }
    let values = std::slice::from_raw_parts(input, length);
    let n_raw = values[0];
    if n_raw < 1 || n_raw > MAX_N as i64 { return -1; }
    let n = n_raw as usize;
    if length != 1 + 3 * n { return -1; }
    for i in 0..n {
        let index = values[1 + i];
        let a_value = values[1 + n + i];
        let b_value = values[1 + 2 * n + i];
        if index < 0 || index >= n as i64 { return -1; }
        if !(0..=MAX_VALUE).contains(&a_value) || !(0..=MAX_VALUE).contains(&b_value) { return -1; }
    }

    let mut sum = 0i64;
    for i in 0..n {
        let index = values[1 + i] as usize;
        sum += values[1 + n + i] * values[1 + 2 * n + index];
    }
    sum
}
