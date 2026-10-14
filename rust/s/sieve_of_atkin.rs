/// Count primes through limit with the Sieve of Atkin.
#[no_mangle]
pub extern "C" fn sieve_of_atkin(limit: i64) -> i64 {
    if !(0..=4096).contains(&limit) {
        return -1;
    }
    if limit < 2 {
        return 0;
    }
    let n = limit as usize;
    let mut sieve = [false; 4097];
    let mut x = 1usize;
    while x <= n / x {
        let x2 = x * x;
        let mut y = 1usize;
        while y <= n / y {
            let y2 = y * y;
            let first = 4 * x2 + y2;
            if first <= n && (first % 12 == 1 || first % 12 == 5) { sieve[first] = !sieve[first]; }
            let second = 3 * x2 + y2;
            if second <= n && second % 12 == 7 { sieve[second] = !sieve[second]; }
            if x > y {
                let third = 3 * x2 - y2;
                if third <= n && third % 12 == 11 { sieve[third] = !sieve[third]; }
            }
            y += 1;
        }
        x += 1;
    }
    let mut candidate = 5usize;
    while candidate <= n / candidate {
        if sieve[candidate] {
            let square = candidate * candidate;
            let mut multiple = square;
            while multiple <= n {
                sieve[multiple] = false;
                multiple += square;
            }
        }
        candidate += 1;
    }
    let mut count = 1i64;
    if n >= 3 { count += 1; }
    for value in 5..=n { count += sieve[value] as i64; }
    count
}
