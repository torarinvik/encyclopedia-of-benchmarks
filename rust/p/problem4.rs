fn is_palindrome(value: i64) -> bool {
    let mut remaining = value;
    let mut reversed = 0i64;
    while remaining > 0 {
        reversed = reversed * 10 + remaining % 10;
        remaining /= 10;
    }
    reversed == value
}

#[no_mangle]
pub extern "C" fn problem4(digits: i64) -> i64 {
    if !(1..=3).contains(&digits) {
        return -1;
    }
    let minimum = match digits { 1 => 1, 2 => 10, _ => 100 };
    let maximum = match digits { 1 => 9, 2 => 99, _ => 999 };
    let mut largest = 0i64;
    let mut first = maximum;
    while first >= minimum && first * maximum > largest {
        let mut second = maximum;
        while second >= first && first * second > largest {
            let product = first * second;
            if is_palindrome(product) {
                largest = product;
            }
            second -= 1;
        }
        first -= 1;
    }
    largest
}
