#[no_mangle]
pub extern "C" fn mersenne_primes(n: i64) -> i64 {
    if !(2..=31).contains(&n) { return -1; }
    if n == 2 { return 1; }
    let modulus = (1i64 << n) - 1;
    let mut residue = 4i64;
    for _ in 0..(n - 2) {
        residue = (residue * residue - 2) % modulus;
    }
    if residue == 0 { 1 } else { 0 }
}
