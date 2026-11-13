const MODULUS: i64 = 1_000_000_007;

fn power_mod(mut base: i64, mut exponent: i64) -> i64 {
    let mut result = 1;
    while exponent > 0 {
        if exponent & 1 != 0 { result = result * base % MODULUS; }
        base = base * base % MODULUS;
        exponent >>= 1;
    }
    result
}

#[no_mangle]
pub unsafe extern "C" fn turnstile_one_sparse_fingerprint_recovery(
    input: *const i64, length: usize,
) -> i64 {
    if input.is_null() || !(3..=260).contains(&length) { return -1; }
    let values = std::slice::from_raw_parts(input, length);
    let (n, q, base) = (values[0], values[1], values[2]);
    if !(1..=64).contains(&n) || !(0..=128).contains(&q) || !(1..MODULUS).contains(&base)
        || length != (3 + 2 * q) as usize { return -1; }
    let (mut mass, mut weighted, mut fingerprint) = (0i64, 0i64, 0i64);
    for i in 0..q as usize {
        let (index, delta) = (values[3 + 2 * i], values[4 + 2 * i]);
        if !(0..n).contains(&index) || !(-1000..=1000).contains(&delta) { return -1; }
        mass += delta;
        weighted += delta * index;
        fingerprint = (fingerprint + delta * power_mod(base, index)).rem_euclid(MODULUS);
    }
    if mass == 0 || weighted % mass != 0 { return 0; }
    let index = weighted / mass;
    if !(0..n).contains(&index) { return 0; }
    if fingerprint == (mass * power_mod(base, index)).rem_euclid(MODULUS) { index + 1 } else { 0 }
}
