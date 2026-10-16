const MAX_LIMIT: i64 = 1000;

#[no_mangle]
pub extern "C" fn problem120(limit: i64) -> i64 {
    if !(0..=MAX_LIMIT).contains(&limit) { return -1; }
    let mut total = 0i64;
    for a in 3..=limit { total += 2 * a * ((a - 1) / 2); }
    total
}
