const MAX_CAPACITY: i64 = 64;
const MAX_RATE: i64 = 32;
const MAX_REQUESTS: i64 = 63;
const MAX_TICKS: i64 = 256;
const MAX_INPUT: usize = 66;

#[no_mangle]
pub unsafe extern "C" fn token_bucket_rate_limiter_virtual_time(input: *const i64, length: usize) -> i64 {
    if input.is_null() || length < 3 || length > MAX_INPUT { return -1; }
    let input = unsafe { std::slice::from_raw_parts(input, length) };
    let capacity = input[0];
    let rate = input[1];
    let qv = input[2];
    if !(0..=MAX_CAPACITY).contains(&capacity) || !(0..=MAX_RATE).contains(&rate) ||
        !(0..=MAX_REQUESTS).contains(&qv) || length != 3 + qv as usize { return -1; }
    let q = qv as usize;
    if input[3..].iter().any(|&ticks| !(0..=MAX_TICKS).contains(&ticks)) { return -1; }

    let mut tokens = capacity;
    let mut allowed = 0u64;
    for (i, &ticks) in input[3..3 + q].iter().enumerate() {
        tokens = (tokens + ticks * rate).min(capacity);
        if tokens > 0 {
            allowed |= 1u64 << i;
            tokens -= 1;
        }
    }
    allowed as i64
}
