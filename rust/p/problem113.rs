/// Count non-bouncy positive integers with at most the requested digits.
const MAX_DIGITS: i64 = 100;

fn choose_integer(n: i64, r: i64) -> i64 {
    let mut result = 1i64;
    for i in 1..=r {
        result = result * (n + 1 - i) / i;
    }
    result
}

fn non_bouncy_exact(digits: i64) -> i64 {
    choose_integer(8 + digits, digits) + choose_integer(9 + digits, digits) - 10
}

#[no_mangle]
pub extern "C" fn problem113(num_digits: i64) -> i64 {
    if num_digits > MAX_DIGITS { return -1; }
    let mut total = 0i64;
    let mut digits = 1i64;
    while digits <= num_digits {
        total += non_bouncy_exact(digits);
        digits += 1;
    }
    total
}
