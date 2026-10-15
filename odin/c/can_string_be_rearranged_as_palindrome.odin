package can_string_be_rearranged_as_palindrome

import "core:c"

// Can lowercase ASCII letters be rearranged into a palindrome?
@(export)
can_string_be_rearranged_as_palindrome :: proc "c" (text: [^]i64, length: c.size_t) -> i64 {
    if length == 0 || length > 4096 do return -1
    counts: [26]c.size_t = {}
    odd_count: c.size_t = 0
    for index := c.size_t(0); index < length; index += 1 {
        value := text[index]
        if value < 97 || value > 122 do return -1
        letter := c.size_t(value - 97)
        if counts[letter] % 2 == 0 { odd_count += 1 } else { odd_count -= 1 }
        counts[letter] += 1
    }
    if odd_count <= 1 { return 1 }
    return 0
}
