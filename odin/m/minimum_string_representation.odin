package minimum_string_representation

import "core:c"

// Least cyclic rotation by two-candidate elimination.
@(export)
minimum_string_representation :: proc "c" (values: [^]i64, length: c.size_t) -> i64 {
    if length > 4096 do return -1
    if length == 0 do return 0
    if values == nil do return -1
    for index: c.size_t = 0; index < length; index += 1 {
        if values[index] < 0 || values[index] > 127 do return -1
    }

    left, right, matched := c.size_t(0), c.size_t(1), c.size_t(0)
    for left < length && right < length && matched < length {
        a := values[(left + matched) % length]
        b := values[(right + matched) % length]
        if a == b {
            matched += 1
            continue
        }
        if a > b {
            left += matched + 1
            if left == right do left += 1
        } else {
            right += matched + 1
            if left == right do right += 1
        }
        matched = 0
    }
    if left < right do return i64(left)
    return i64(right)
}
