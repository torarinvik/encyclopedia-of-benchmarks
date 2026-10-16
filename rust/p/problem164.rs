#[no_mangle]
pub extern "C" fn problem164(n_digits: i64) -> i64 {
    if !(0..=26).contains(&n_digits) { return -1; }
    if n_digits == 0 { return 1; }

    let mut current = [0i64; 100];
    let mut next = [0i64; 100];
    for first in 1..=9 { current[first * 10] = 1; }

    for _used in 1..n_digits {
        next.fill(0);
        for previous in 0..=9 {
            for before_previous in 0..=9 {
                let ways = current[previous * 10 + before_previous];
                let maximum_digit = 9 - previous - before_previous;
                for digit in 0..=maximum_digit {
                    next[digit * 10 + previous] += ways;
                }
            }
        }
        std::mem::swap(&mut current, &mut next);
    }

    current.iter().sum()
}
