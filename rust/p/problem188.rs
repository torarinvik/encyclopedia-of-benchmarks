fn modexpt(base: i64, exponent: i64, modulus: i64) -> i64 {
    if exponent == 1 { return base; }
    if exponent % 2 == 0 {
        let half = modexpt(base, exponent / 2, modulus) % modulus;
        return (half * half) % modulus;
    }
    (base * modexpt(base, exponent - 1, modulus)) % modulus
}

#[no_mangle]
pub extern "C" fn problem188(base: i64, height: i64, digits: i64) -> i64 {
    if !(1..=1_000_000_000).contains(&base) || base % 10 == 0
        || !(1..=10_000).contains(&height) || !(1..=8).contains(&digits) { return -1; }
    let modulus = 10i64.pow(digits as u32);
    let mut result = base;
    for _ in 1..height { result = modexpt(base, result, modulus); }
    result
}
