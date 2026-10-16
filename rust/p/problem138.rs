#[no_mangle]
pub extern "C" fn problem138(count: i64) -> i64 {
    if count > 14 { return -1; }
    if count <= 0 { return 0; }
    let mut m = 2_i64;
    let mut l = 1_i64;
    let mut total = 0_i64;
    for _ in 0..count {
        let next_m = 9 * m + 20 * l;
        let next_l = 4 * m + 9 * l;
        m = next_m;
        l = next_l;
        total += l;
    }
    total
}
