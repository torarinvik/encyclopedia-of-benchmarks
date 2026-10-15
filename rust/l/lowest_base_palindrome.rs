/// Smallest base in which a nonnegative integer is palindromic.
fn is_palindromic_in_base(number: i64, base: i64) -> bool {
    if number <= 1 { return true; }
    if number % base == 0 { return false; }
    let mut remaining = number;
    let mut reversed = 0i64;
    while remaining > 0 {
        reversed = reversed * base + remaining % base;
        remaining /= base;
    }
    reversed == number
}

#[no_mangle]
pub extern "C" fn lowest_base_palindrome(number: i64) -> i64 {
    if !(0..=64).contains(&number) { return -1; }
    let mut base = 2i64;
    while !is_palindromic_in_base(number, base) { base += 1; }
    base
}
