/// Bounded port of TheAlgorithms/Python Project Euler 26 remainder search.
#[no_mangle]
pub extern "C" fn problem26(limit: i64) -> i64 {
    if !(0..=1000).contains(&limit) {
        return -1;
    }
    let mut best_denominator = 1i64;
    let mut longest_remainder_list = 0i64;
    for denominator in 1..=limit {
        let mut seen = [false; 1001];
        let mut remainder = 1i64;
        let mut remainder_count = 0i64;
        for _ in 0..limit {
            if seen[remainder as usize] {
                if remainder_count > longest_remainder_list {
                    longest_remainder_list = remainder_count;
                    best_denominator = denominator;
                }
                break;
            }
            seen[remainder as usize] = true;
            remainder_count += 1;
            remainder = remainder * 10 % denominator;
        }
    }
    best_denominator
}
