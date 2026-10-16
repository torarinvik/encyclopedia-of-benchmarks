#[no_mangle]
pub extern "C" fn problem124(n_max: i64, k: i64) -> i64 {
    if n_max < 1 || n_max > 100_000 || k < 1 || k > n_max { return -1; }
    let n = n_max as usize;
    let mut radicals = [0_i64; 100_001];
    let mut counts = [0_i64; 100_001];
    for i in 1..=n { radicals[i] = 1; }
    for p in 2..=n {
        if radicals[p] == 1 {
            for multiple in (p..=n).step_by(p) { radicals[multiple] *= p as i64; }
        }
    }
    for i in 1..=n { counts[radicals[i] as usize] += 1; }
    let mut remaining = k;
    for rad in 1..=n {
        if remaining > counts[rad] { remaining -= counts[rad]; continue; }
        for value in 1..=n {
            if radicals[value] == rad as i64 {
                remaining -= 1;
                if remaining == 0 { return value as i64; }
            }
        }
    }
    -1
}
