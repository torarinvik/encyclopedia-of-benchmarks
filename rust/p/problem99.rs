const MAX_PAIR_COUNT: i64 = 1000;
const MAX_BASE: i64 = 1_000_000;
const MAX_EXPONENT: i64 = 1_200_000;

#[no_mangle]
pub extern "C" fn problem99(input: *const i64, length: usize) -> i64 {
    if input.is_null() || length < 1 { return -1; }
    let values = unsafe { std::slice::from_raw_parts(input, length) };
    let pair_count_value = values[0];
    if pair_count_value < 0 || pair_count_value > MAX_PAIR_COUNT { return -1; }
    let pair_count = pair_count_value as usize;
    if length != 1 + 2 * pair_count { return -1; }

    let mut largest = 0.0f64;
    let mut result = 0i64;
    for index in 0..pair_count {
        let base = values[1 + 2 * index];
        let exponent = values[2 + 2 * index];
        if base < 1 || base > MAX_BASE || exponent < 0 || exponent > MAX_EXPONENT { return -1; }
        let value = (exponent as f64) * (base as f64).log10();
        if value > largest {
            largest = value;
            result = index as i64 + 1;
        }
    }
    result
}
