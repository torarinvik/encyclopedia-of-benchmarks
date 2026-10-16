/// Find the first odd prime index whose source remainder exceeds the limit.
const MAX_LIMIT: i64 = 10_000_000_000;
const PRIME_LIMIT: usize = 300_000;

#[no_mangle]
pub extern "C" fn problem123(limit: i64) -> i64 {
    if limit > MAX_LIMIT { return -1; }
    let mut composite = [false; PRIME_LIMIT + 1];
    let mut factor = 2usize;
    while factor * factor <= PRIME_LIMIT {
        if !composite[factor] {
            let mut multiple = factor * factor;
            while multiple <= PRIME_LIMIT {
                composite[multiple] = true;
                multiple += factor;
            }
        }
        factor += 1;
    }
    let mut n = 1i64;
    let mut skip_next = false;
    for candidate in 2..=PRIME_LIMIT {
        if composite[candidate] { continue; }
        if skip_next { skip_next = false; continue; }
        if 2 * candidate as i64 * n > limit { return n; }
        skip_next = true;
        n += 2;
    }
    -1
}
