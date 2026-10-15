package lowest_base_palindrome

// Smallest base in which a nonnegative integer is palindromic.
is_palindromic_in_base :: proc(number, base: i64) -> bool {
    if number <= 1 do return true
    if number % base == 0 do return false
    remaining := number
    reversed := i64(0)
    for remaining > 0 {
        reversed = reversed * base + remaining % base
        remaining /= base
    }
    return reversed == number
}

@(export)
lowest_base_palindrome :: proc "c" (number: i64) -> i64 {
    if number < 0 || number > 64 do return -1
    base := i64(2)
    for !is_palindromic_in_base(number, base) { base += 1 }
    return base
}
