const MAX_LIMIT: i64 = 1_000_000;

fn is_decimal_palindrome(value: i64) -> bool {
    let mut remaining = value;
    let mut reversed = 0i64;
    while remaining > 0 {
        reversed = reversed * 10 + remaining % 10;
        remaining /= 10;
    }
    reversed == value
}

fn is_binary_palindrome(value: i64) -> bool {
    let mut remaining = value;
    let mut reversed = 0i64;
    while remaining > 0 {
        reversed = reversed * 2 + remaining % 2;
        remaining /= 2;
    }
    reversed == value
}

/// Sum positive integers below `limit` that are palindromic in base 10 and base 2.
#[no_mangle]
pub extern "C" fn problem36(limit: i64) -> i64 {
    if !(0..=MAX_LIMIT).contains(&limit) {
        return -1;
    }
    let mut total = 0i64;
    for value in 1..limit {
        if is_decimal_palindrome(value) && is_binary_palindrome(value) {
            total += value;
        }
    }
    total
}
