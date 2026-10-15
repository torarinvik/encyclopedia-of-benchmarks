/// Smallest base in which a nonnegative integer is palindromic.
fn isPalindromicInBase(number: i64, base: i64) bool {
    if (number <= 1) return true;
    if (@mod(number, base) == 0) return false;
    var remaining = number;
    var reversed: i64 = 0;
    while (remaining > 0) {
        reversed = reversed * base + @mod(remaining, base);
        remaining = @divTrunc(remaining, base);
    }
    return reversed == number;
}

export fn lowest_base_palindrome(number: i64) i64 {
    if (number < 0 or number > 64) return -1;
    var base: i64 = 2;
    while (!isPalindromicInBase(number, base)) : (base += 1) {}
    return base;
}
