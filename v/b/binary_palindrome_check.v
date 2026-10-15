module binary_palindrome_check

@[export: 'binary_palindrome_check']
pub fn binary_palindrome_check(number i64) i64 {
    if number < -2147483648 || number > 2147483647 { return -1 }
    if number < 0 { return 0 }
    mut remaining := number
    mut reversed := i64(0)
    for remaining > 0 {
        reversed = (reversed << 1) | (remaining & 1)
        remaining >>= 1
    }
    if reversed == number { return 1 }
    return 0
}
