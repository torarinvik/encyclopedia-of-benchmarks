const INVALID_RESULT: i64 = i64::MIN;

fn inverse(a: i64, m: i64) -> i64 {
    let (mut old_r, mut r) = (a, m);
    let (mut old_s, mut s) = (1_i64, 0_i64);
    while r != 0 {
        let quotient = old_r / r;
        (old_r, r) = (r, old_r - quotient * r);
        (old_s, s) = (s, old_s - quotient * s);
    }
    if old_r == 1 { (old_s + m) % m } else { -1 }
}

/// Compute the pinned factorial-table nCr modulo p contract.
#[no_mangle]
pub extern "C" fn ncr_modulo_p(values: *const i64, length: usize) -> i64 {
    if values.is_null() || length != 4 { return INVALID_RESULT; }
    let values = unsafe { std::slice::from_raw_parts(values, length) };
    let (size, p, n, r) = (values[0], values[1], values[2], values[3]);
    if !(0..=64).contains(&size) || !(2..=1009).contains(&p) || n < 0 || n > size || !(0..=64).contains(&r) {
        return INVALID_RESULT;
    }
    let mut fac = [0_i64; 65];
    fac[0] = 1;
    for i in 1..=size as usize { fac[i] = (fac[i - 1] * i as i64) % p; }
    if r > n { return 0; }
    if r == 1 { return n % p; }
    if r == 0 || r == n { return 1; }
    let denominator = (fac[r as usize] * fac[(n - r) as usize]) % p;
    let denominator_inv = inverse(denominator, p);
    if denominator_inv < 0 { return -1; }
    (fac[n as usize] * denominator_inv) % p
}
