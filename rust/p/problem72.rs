#[no_mangle]
pub extern "C" fn problem72(limit: i64) -> i64 {
    if !(0..=1_000_000).contains(&limit) { return -1; }
    if limit < 2 { return 0; }
    let n = limit as usize;
    let mut phi = vec![0u32; n + 1];
    if n >= 1 { phi[1] = 1; }
    for value in 2..=n { phi[value] = value as u32; }
    for prime in 2..=n {
        if phi[prime] == prime as u32 {
            for multiple in (prime..=n).step_by(prime) {
                phi[multiple] -= phi[multiple] / prime as u32;
            }
        }
    }
    phi.iter().skip(2).map(|&value| i64::from(value)).sum()
}
