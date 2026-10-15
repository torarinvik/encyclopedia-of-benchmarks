package case_insensitive_palindrome

import "core:c"


// Check whether an ASCII string is a palindrome ignoring ASCII letter case.
@(export)
case_insensitive_palindrome :: proc "c" (values: [^]i64, length: c.size_t) -> i64 {
    if length > 4096 do return -1
    for index := c.size_t(0); index < length; index += 1 {
        if values[index] < 0 || values[index] > 127 do return -1
    }
    for left := c.size_t(0); left < length / 2; left += 1 {
        first := values[left]
        last := values[length - 1 - left]
        if first >= 65 && first <= 90 do first += 32
        if last >= 65 && last <= 90 do last += 32
        if first != last do return 0
    }
    return 1
}
