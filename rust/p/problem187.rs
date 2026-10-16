fn is_composite(bits: &[u64], value: i64) -> bool {
    ((bits[(value >> 6) as usize] >> ((value & 63) as u32)) & 1) != 0
}
fn mark_composite(bits: &mut [u64], value: i64) {
    bits[(value >> 6) as usize] |= 1u64 << ((value & 63) as u32);
}

#[no_mangle]
pub extern "C" fn problem187(max_number: i64) -> i64 {
    if !(0..=100_000_000).contains(&max_number) { return -1; }
    let prime_limit = max_number / 2;
    if prime_limit <= 2 { return 0; }
    let mut composite = vec![0u64; ((prime_limit + 63) / 64) as usize];
    mark_composite(&mut composite, 0);
    mark_composite(&mut composite, 1);
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

    let mut right_value = prime_limit - 1;
    while right_value >= 2 && is_composite(&composite, right_value) { right_value -= 1; }
    if right_value < 2 { return 0; }
    let mut prime_count = 0i64;
    for value in 2..=right_value {
        if !is_composite(&composite, value) { prime_count += 1; }
    }

    let (mut right_rank, mut left_rank, mut count) = (prime_count - 1, 0i64, 0i64);
    for left_value in 2..=right_value {
        if is_composite(&composite, left_value) { continue; }
        while right_rank >= left_rank && left_value * right_value >= max_number {
            right_rank -= 1;
            right_value -= 1;
            while right_value >= 2 && is_composite(&composite, right_value) { right_value -= 1; }
        }
        if right_rank < left_rank { break; }
        count += right_rank - left_rank + 1;
        left_rank += 1;
    }
    count
}
