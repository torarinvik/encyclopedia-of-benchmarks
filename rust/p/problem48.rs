const MODULUS: i64 = 10_000_000_000;

#[no_mangle]
pub extern "C" fn problem48(ignored: i64) -> i64 {
    if ignored != 0 {
        return -1;
    }
    let mut total = 0;
    for base in 1..=1000 {
        let mut term = 1;
        for _ in 0..base {
            term = (term * base) % MODULUS;
        }
        total = (total + term) % MODULUS;
    }
    total
}
