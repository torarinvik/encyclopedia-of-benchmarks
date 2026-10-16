#[no_mangle]
pub extern "C" fn problem136(n_limit: i64) -> i64 {
    if n_limit > 100_000 { return -1; }
    if n_limit <= 0 { return 0; }
    let limit = n_limit as usize;
    let mut solutions = [0_u8; 100_000];
    let max_delta = (n_limit + 1) / 4;
    for delta in 1..=max_delta {
        let mut y = 4 * delta - 1;
        while y > delta {
            let n = y * (4 * delta - y);
            if n >= n_limit { break; }
            let slot = &mut solutions[n as usize];
            if *slot < 2 { *slot += 1; }
            y -= 1;
        }
    }
    solutions[..limit].iter().filter(|&&count| count == 1).count() as i64
}
