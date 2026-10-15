package valid_palindrome

import "core:c"

is_ascii_alphanumeric :: proc "contextless" (value: i64) -> bool {
    return (value >= 48 && value <= 57) || (value >= 65 && value <= 90) ||
           (value >= 97 && value <= 122)
}

ascii_lower :: proc "contextless" (value: i64) -> i64 {
    if value >= 65 && value <= 90 do return value + 32
    return value
}

// ASCII alphanumeric palindrome check, ignoring case and punctuation.
@(export)
valid_palindrome :: proc "c" (text: [^]i64, length: c.size_t) -> i64 {
    if length > 4096 do return -1
    for index := c.size_t(0); index < length; index += 1 {
        if text[index] < 0 || text[index] > 127 do return -1
    }
    left := c.size_t(0)
    right := length
    for left < right {
        for left < right && !is_ascii_alphanumeric(text[left]) { left += 1 }
        for left < right && !is_ascii_alphanumeric(text[right - 1]) { right -= 1 }
        if left < right && ascii_lower(text[left]) != ascii_lower(text[right - 1]) do return 0
        if left < right {
            left += 1
            right -= 1
        }
    }
    return 1
}
