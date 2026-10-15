module case_insensitive_palindrome

fn ascii_lower(value i64) i64 {
    if value >= 65 && value <= 90 { return value + 32 }
    return value
}


// Check whether an ASCII string is a palindrome ignoring ASCII letter case.
@[export: 'case_insensitive_palindrome']
pub fn case_insensitive_palindrome(values &i64, length usize) i64 {
    if length > 4096 { return -1 }
    for index in 0 .. length {
        value := unsafe { values[index] }
        if value < 0 || value > 127 { return -1 }
    }
    for left in 0 .. length / 2 {
        first := unsafe { values[left] }
        last := unsafe { values[length - 1 - left] }
        if ascii_lower(first) != ascii_lower(last) { return 0 }
    }
    return 1
}
