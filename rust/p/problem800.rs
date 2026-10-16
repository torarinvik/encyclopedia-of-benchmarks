fn is_composite(bits: &[u64], value: i64) -> bool {
    ((bits[(value >> 6) as usize] >> ((value & 63) as u32)) & 1) != 0
}
fn mark_composite(bits: &mut [u64], value: i64) {
    bits[(value >> 6) as usize] |= 1u64 << ((value & 63) as u32);
}

#[no_mangle]
pub extern "C" fn problem800(base: i64, degree: i64) -> i64 {
    if !(2..=1_000_000).contains(&base) || !(1..=1_000_000).contains(&degree) { return -1; }
    let upper_bound = degree as f64 * (base as f64).log2();
    let prime_limit = upper_bound as i64;
    if prime_limit <= 2 { return 0; }
    let mut composite = vec![0u64; ((prime_limit + 63) / 64) as usize];
    let mut prime = 2i64;
    while prime <= (prime_limit - 1) / prime {
        if !is_composite(&composite, prime) {
            let mut multiple = prime * prime;
            while multiple < prime_limit {
                mark_composite(&mut composite, multiple);
                multiple += prime;
            }
        }
        prime += 1;
    }

    let mut right_value = 0i64;
    let mut prime_count = 0i64;
    for value in 2..prime_limit {
        if !is_composite(&composite, value) { right_value = value; prime_count += 1; }
    }
    if prime_count < 2 { return 0; }

    let (mut right_rank, mut left_rank, mut left_value, mut count) = (prime_count - 1, 0i64, 2i64, 0i64);
    while left_rank < right_rank {
        while is_composite(&composite, left_value) { left_value += 1; }
        let left_log = (left_value as f64).log2();
        while right_value as f64 * left_log + left_value as f64 * (right_value as f64).log2() > upper_bound {
            right_rank -= 1;
            right_value -= 1;
            while right_value >= 2 && is_composite(&composite, right_value) { right_value -= 1; }
        }
        count += right_rank - left_rank;
        left_rank += 1;
        left_value += 1;
    }
    count
}
