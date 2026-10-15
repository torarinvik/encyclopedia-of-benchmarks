module valid_palindrome

fn is_ascii_alphanumeric(value i64) bool {
    return (value >= 48 && value <= 57) || (value >= 65 && value <= 90) ||
        (value >= 97 && value <= 122)
}

fn ascii_lower(value i64) i64 {
    if value >= 65 && value <= 90 { return value + 32 }
    return value
}

// ASCII alphanumeric palindrome check, ignoring case and punctuation.
@[export: 'valid_palindrome']
pub fn valid_palindrome(text &i64, length usize) i64 {
    if length > 4096 { return -1 }
    for index in 0 .. length {
        value := unsafe { text[index] }
        if value < 0 || value > 127 { return -1 }
    }
    mut left := usize(0)
    mut right := length
    for left < right {
        for left < right && !is_ascii_alphanumeric(unsafe { text[left] }) { left++ }
        for left < right && !is_ascii_alphanumeric(unsafe { text[right - 1] }) { right-- }
        if left < right && ascii_lower(unsafe { text[left] }) != ascii_lower(unsafe { text[right - 1] }) {
            return 0
        }
        if left < right { left++; right-- }
    }
    return 1
}
