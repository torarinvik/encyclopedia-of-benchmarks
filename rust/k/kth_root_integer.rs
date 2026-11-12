fn power_at_most(base: i64, mut exponent: i64, limit: i64) -> bool {
    if base == 0 { return true; }
    let mut product = 1i64;
    while exponent > 0 {
        if product > limit / base { return false; }
        product *= base;
        exponent -= 1;
    }
    true
}

#[no_mangle]
pub unsafe extern "C" fn kth_root_integer(input: *const i64, length: usize) -> i64 {
    if input.is_null() || length != 2 { return -1; }
    let values = std::slice::from_raw_parts(input, length);
    let number = values[0];
    let degree = values[1];
    if number < 0 || !(1..=64).contains(&degree) { return -1; }

    let mut low = 0i64;
    let mut high = number;
    while low < high {
        let difference = high - low;
        let candidate = low + difference / 2 + difference % 2;
        if power_at_most(candidate, degree, number) { low = candidate; }
        else { high = candidate - 1; }
    }
    low
}
