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
pub extern "C" fn problem7(index: i64) -> i64 {
    if !(1..=10_001).contains(&index) {
        return -1;
    }
    let mut count = 0i64;
    let mut candidate = 1i64;
    while count < index {
        candidate += 1;
        if is_prime(candidate) {
            count += 1;
        }
    }
    candidate
}
