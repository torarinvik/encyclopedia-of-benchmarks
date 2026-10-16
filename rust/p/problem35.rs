const MAX_LIMIT: usize = 1_000_000;
const ODD_SLOTS: usize = MAX_LIMIT / 2 + 1;

#[no_mangle]
pub extern "C" fn problem35(ignored: i64) -> i64 {
    if ignored != 0 {
        return -1;
    }
    let mut odd_prime = [false; ODD_SLOTS];
    odd_prime[1..].fill(true);

    let mut candidate = 3usize;
    while candidate <= MAX_LIMIT / candidate {
        if odd_prime[candidate / 2] {
            let mut composite = candidate * candidate;
            while composite <= MAX_LIMIT {
                odd_prime[composite / 2] = false;
                composite += 2 * candidate;
            }
        }
        candidate += 2;
    }

    let mut count = 1i64;
    let mut number = 3usize;
    while number <= MAX_LIMIT {
        if odd_prime[number / 2] {
            let mut remaining = number;
            let mut has_even_digit = false;
            while remaining > 0 {
                if (remaining % 10) % 2 == 0 {
                    has_even_digit = true;
                    break;
                }
                remaining /= 10;
            }
            if !has_even_digit {
                let mut power10 = 1usize;
                let mut digits = 1usize;
                remaining = number;
                while remaining >= 10 {
                    power10 *= 10;
                    remaining /= 10;
                    digits += 1;
                }
                let mut rotation = number;
                let mut circular = true;
                for _ in 0..digits {
                    if !odd_prime[rotation / 2] {
                        circular = false;
                        break;
                    }
                    rotation = (rotation % 10) * power10 + rotation / 10;
                }
                if circular {
                    count += 1;
                }
            }
        }
        number += 2;
    }
    count
}
