#[no_mangle]
pub extern "C" fn so1(threshold: i64) -> i64 {
    if !(-2_147_483_648..=1_000_000_000).contains(&threshold) {
        return -1;
    }

    let mut first = 1_i64;
    let mut second = 2_i64;
    let mut total = 0_i64;
    while second <= threshold {
        if second % 2 == 0 {
            total += second;
        }
        let temporary = first;
        first = second;
        second = temporary + first;
    }
    total
}
