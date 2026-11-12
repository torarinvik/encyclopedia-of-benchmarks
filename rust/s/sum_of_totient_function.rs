const MAX_N: i64 = 1_000_000_000;
const BASE_LIMIT: usize = 100_000;
const MAX_CACHE: usize = (MAX_N as usize) / BASE_LIMIT + 2;
const MODULUS: i64 = 998_244_353;

fn triangular_mod(n: i64) -> i64 {
    let (mut left, mut right) = (n, n + 1);
    if left % 2 == 0 { left /= 2; }
    else { right /= 2; }
    (left % MODULUS) * (right % MODULUS) % MODULUS
}

fn summatory_phi(value: i64, total_n: i64, prefix: &[i64; BASE_LIMIT + 1],
                 memo: &mut [i64; MAX_CACHE], visited: &mut [bool; MAX_CACHE]) -> i64 {
    if value <= BASE_LIMIT as i64 { return prefix[value as usize]; }
    let cache_index = (total_n / value) as usize;
    if visited[cache_index] { return memo[cache_index]; }

    let mut answer = triangular_mod(value);
    let mut left = 2i64;
    while left <= value {
        let quotient = value / left;
        let right = value / quotient;
        let block_size = right - left + 1;
        let sub_sum = summatory_phi(quotient, total_n, prefix, memo, visited);
        let contribution = (block_size % MODULUS) * sub_sum % MODULUS;
        answer = (answer - contribution + MODULUS) % MODULUS;
        left = right + 1;
    }
    visited[cache_index] = true;
    memo[cache_index] = answer;
    answer
}

#[no_mangle]
pub extern "C" fn sum_of_totient_function(n: i64) -> i64 {
    if !(1..=MAX_N).contains(&n) { return -1; }
    let mut prefix = [0i64; BASE_LIMIT + 1];
    for value in 0..=BASE_LIMIT { prefix[value] = value as i64; }
    let sieve_limit = (n as usize).min(BASE_LIMIT);
    for prime in 2..=sieve_limit {
        if prefix[prime] != prime as i64 { continue; }
        for multiple in (prime..=sieve_limit).step_by(prime) {
            prefix[multiple] -= prefix[multiple] / prime as i64;
        }
    }
    let mut running = 0i64;
    for value in 1..=sieve_limit {
        running = (running + prefix[value]) % MODULUS;
        prefix[value] = running;
    }
    if n <= BASE_LIMIT as i64 { return prefix[n as usize]; }

    let mut memo = [0i64; MAX_CACHE];
    let mut visited = [false; MAX_CACHE];
    summatory_phi(n, n, &prefix, &mut memo, &mut visited)
}
