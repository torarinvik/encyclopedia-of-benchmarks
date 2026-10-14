package palindrome

import "core:c"

// Check whether an exact ASCII string is a palindrome.
@(export)
palindrome :: proc "c" (values: [^]i64, length: c.size_t) -> i64 {
    if length > 4096 do return -1
    for index := c.size_t(0); index < length; index += 1 {
        if values[index] < 0 || values[index] > 127 do return -1
    }
    for left := c.size_t(0); left < length / 2; left += 1 {
        if values[left] != values[length - 1 - left] do return 0
    }
    return 1
}
