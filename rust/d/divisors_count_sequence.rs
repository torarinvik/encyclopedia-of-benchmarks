const MAX_INDEX: i64 = 9_999;

#[no_mangle]
pub extern "C" fn divisors_count_sequence(index: i64) -> i64 {
    if index < 0 || index > MAX_INDEX {
        return -1;
    }
    let n = index + 1;
    if n == 1 {
        return 1;
    }
    let mut count = 2i64;
    let mut k = 2i64;
    while k < n {
        if n % k == 0 {
            count += 1;
        }
        k += 1;
    }
    count
}
