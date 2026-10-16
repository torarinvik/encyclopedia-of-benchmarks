/// Count distinct powers using maximal perfect-power roots.
#[no_mangle]
pub extern "C" fn problem29(limit: i64) -> i64 {
    if !(1..=100).contains(&limit) { return -1; }
    if limit == 1 { return 0; }
    let mut roots = [0_i64; 101];
    let mut exponents = [0_i64; 101];
    let mut seen = [false; 60701];
    let mut distinct = 0_i64;
    for a in 2..=limit as usize {
        roots[a] = a as i64;
        exponents[a] = 1;
        for candidate_exponent in 2..=6_i64 {
            for candidate_root in 2..=a as i64 {
                let mut power = 1_i64;
                for _ in 0..candidate_exponent {
                    power *= candidate_root;
                    if power > a as i64 { break; }
                }
                if power == a as i64 && candidate_exponent > exponents[a] {
                    roots[a] = candidate_root;
                    exponents[a] = candidate_exponent;
                }
            }
        }
        for b in 2..=limit {
            let key = (roots[a] * 601 + exponents[a] * b) as usize;
            if !seen[key] { seen[key] = true; distinct += 1; }
        }
    }
    distinct
}
