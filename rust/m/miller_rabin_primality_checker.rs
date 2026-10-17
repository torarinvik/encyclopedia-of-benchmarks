const MAX_N: i64 = 2_147_483_647;

fn next_word(state: &mut u64) -> u64 {
    *state = state.wrapping_add(0x9E3779B97F4A7C15);
    let mut z = *state;
    z = (z ^ (z >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
    z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
    z ^ (z >> 31)
}
fn mod_power(mut base: i64, mut exponent: i64, modulus: i64) -> i64 {
    let mut result = 1;
    while exponent > 0 {
        if exponent & 1 != 0 { result = (result * base) % modulus; }
        base = (base * base) % modulus;
        exponent >>= 1;
    }
    result
}
fn passes_witness(n: i64, a: i64, d: i64, powers_of_two: i64) -> bool {
    let mut x = mod_power(a, d, n);
    if x == 1 || x == n - 1 { return true; }
    for _ in 1..powers_of_two {
        x = (x * x) % n;
        if x == n - 1 { return true; }
    }
    false
}

#[no_mangle]
pub unsafe extern "C" fn miller_rabin_primality_checker(values: *const i64, length: usize) -> i64 {
    if values.is_null() || length < 3 || length > 4 { return -1; }
    let v = std::slice::from_raw_parts(values, length);
    let (n, rounds, seed) = (v[0], v[1], v[2]);
    if length != 3 || n < 5 || n > MAX_N || (n & 1) == 0 || !(1..=64).contains(&rounds) || !(0..=MAX_N).contains(&seed) { return -1; }
    let mut state = seed as u64;
    let span = (n - 4) as u64;
    let threshold = 0u64.wrapping_sub(span) % span;
    let word = loop { let x = next_word(&mut state); if x >= threshold { break x; } };
    let a = 2 + (word % span) as i64;
    let mut d = n - 1;
    let mut powers_of_two = 0;
    while (d & 1) == 0 { d >>= 1; powers_of_two += 1; }
    for _ in 0..rounds { if !passes_witness(n, a, d, powers_of_two) { return 0; } }
    1
}
