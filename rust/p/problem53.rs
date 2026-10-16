#[no_mangle]
pub extern "C" fn problem53(ignored: i64) -> i64 {
    if ignored != 0 {
        return -1;
    }
    let mut total = 0;
    for n in 1..=100i64 {
        let mut coefficient = 1;
        for r in 1..=n / 2 {
            coefficient = coefficient * (n - r + 1) / r;
            if coefficient > 1_000_000 {
                total += n - 2 * r + 1;
                break;
            }
        }
    }
    total
}
