module palindrome

// Check whether an exact ASCII string is a palindrome.
@[export: 'palindrome']
pub fn palindrome(values &i64, length usize) i64 {
    if length > 4096 { return -1 }
    for index in 0 .. length {
        value := unsafe { values[index] }
        if value < 0 || value > 127 { return -1 }
    }
    for left in 0 .. length / 2 {
        first := unsafe { values[left] }
        last := unsafe { values[length - 1 - left] }
        if first != last { return 0 }
    }
    return 1
}
