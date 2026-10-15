fn is_prime(value: i64) -> bool {
    if value < 2 {
        return false;
    }
    let mut factor = 2i64;
    while factor <= value / factor {
        if value % factor == 0 {
            return false;
        }
        factor += 1;
    }
    true
}

#[no_mangle]
pub extern "C" fn number_of_primes_by_powers_of10_sequence(index: i64) -> i64 {
    if !(0..=3).contains(&index) {
        return -1;
    }
    if index == 0 {
        return 0;
    }
    let mut upper = 10i64;
    for _ in 1..index {
        upper *= 10;
    }
    let mut count = 0i64;
    for value in 2..upper {
        if is_prime(value) {
            count += 1;
        }
    }
    count
}
