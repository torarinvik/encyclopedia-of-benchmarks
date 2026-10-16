const MAX_N: i64 = 15;

#[no_mangle]
pub extern "C" fn problem190(n: i64) -> i64 {
    if !(0..=MAX_N).contains(&n) { return -1; }
    let mut total = 0i64;
    for m in 2..=n {
        let x1 = 2.0 / (m + 1) as f64;
        let mut product = 1.0f64;
        for i in 1..=m {
            let xi = i as f64 * x1;
            product *= xi.powf(i as f64);
        }
        total += product as i64;
    }
    total
}
