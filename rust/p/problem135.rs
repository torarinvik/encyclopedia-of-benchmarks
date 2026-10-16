/// Count values through limit with exactly ten valid arithmetic-progression solutions.
const MAX_LIMIT: i64 = 1_000_000;

#[no_mangle]
pub extern "C" fn problem135(limit: i64) -> i64 {
    if limit > MAX_LIMIT { return -1; }
    if limit < 0 { return 0; }
    let mut frequency = [0u8; 1_000_001];
    let mut first_term = 1i64;
    while first_term <= limit {
        let mut n = first_term;
        while n <= limit {
            let mut common_difference = first_term + n / first_term;
            if common_difference % 4 == 0 {
                common_difference /= 4;
                if first_term > common_difference && first_term < 4 * common_difference {
                    let index = n as usize;
                    if frequency[index] < 11 { frequency[index] += 1; }
                }
            }
            n += first_term;
        }
        first_term += 1;
    }
    let mut count = 0i64;
    for n in 1..=limit as usize {
        if frequency[n] == 10 { count += 1; }
    }
    count
}
