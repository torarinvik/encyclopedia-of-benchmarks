/// Count primes through limit with the linear (Euler) sieve.
#[no_mangle]
pub extern "C" fn linear_sieve(limit: i64) -> i64 {
    if !(0..=4096).contains(&limit) {
        return -1;
    }
    if limit < 2 {
        return 0;
    }
    let mut state = [0i64; 4662];
    for value in 2..=limit {
        let index = value as usize;
        if state[index] == 0 {
            state[index] = value;
            let count = state[4661] as usize;
            state[4097 + count] = value;
            state[4661] += 1;
        }
        let count = state[4661] as usize;
        for prime_index in 0..count {
            let prime = state[4097 + prime_index];
            if prime > state[index] || prime > limit / value {
                break;
            }
            state[(value * prime) as usize] = prime;
        }
    }
    state[4661]
}
