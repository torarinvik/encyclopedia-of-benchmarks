const MAX_LIMIT: i64 = 100_000;
const MAX_PARSEABLE_LENGTH: usize = 2;
const WORD_COUNT: usize = 1_563;

fn digit_sum10(mut value: i64) -> i64 {
    let mut sum = 0;
    while value > 0 {
        sum += value % 10;
        value /= 10;
    }
    sum
}

#[no_mangle]
pub unsafe extern "C" fn self_number_count_sieve(input: *const i64, length: usize) -> i64 {
    if input.is_null() || length < 1 || length > MAX_PARSEABLE_LENGTH { return -1; }
    let limit = *input;
    if length != 1 || limit < 1 || limit > MAX_LIMIT { return -1; }

    let mut generated = [0u64; WORD_COUNT];
    for source in 1..=limit {
        let target = source + digit_sum10(source);
        if target <= limit {
            generated[(target >> 6) as usize] |= 1u64 << (target & 63);
        }
    }
    let mut count = 0;
    for value in 1..=limit {
        if generated[(value >> 6) as usize] & (1u64 << (value & 63)) == 0 { count += 1; }
    }
    count
}
