fn integer_sqrt(value: i64) -> i64 { let mut root = 0; while (root + 1) * (root + 1) <= value { root += 1; } root }
#[no_mangle]
pub extern "C" fn problem87(limit: i64) -> i64 {
    if !(24..=50_000_000).contains(&limit) { return -1; }
    let root = integer_sqrt(limit - 24);
    let bound = root.max(2) as usize;
    let mut prime = vec![true; bound + 1]; prime[0] = false; prime[1] = false;
    for p in 2..=bound { if p * p <= bound && prime[p] { for multiple in (p * p..=bound).step_by(p) { prime[multiple] = false; } } }
    let byte_count = ((limit + 7) / 8) as usize;
    let mut seen = vec![0u8; byte_count];
    for p1 in 2..=bound { if prime[p1] {
        let square = (p1 * p1) as i64;
        for p2 in 2..=bound { if prime[p2] {
            let cube = (p2 * p2 * p2) as i64;
            if square + cube as i64 >= limit - 16 { break; }
            for p3 in 2..=bound { if prime[p3] {
                let total = square + cube + (p3 * p3 * p3 * p3) as i64;
                if total >= limit { break; }
                seen[total as usize >> 3] |= 1 << (total & 7);
            } }
        } }
    } }
    seen.iter().map(|byte| byte.count_ones() as i64).sum()
}
