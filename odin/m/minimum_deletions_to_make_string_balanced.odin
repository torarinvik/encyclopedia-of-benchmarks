package minimum_deletions_balanced

import "core:c"

// Minimum deletions to leave all a values before all b values.
@(export)
minimum_deletions_to_make_string_balanced :: proc "c" (values: [^]i64, length: c.size_t) -> i64 {
    if length > 256 do return -1
    a_state := i64(0)
    b_state := i64(0)
    for index := 0; index < int(length); index += 1 {
        value := values[index]
        if value < 0 || value > 1 do return -1
        if value == 0 && b_state < a_state do b_state += 1
        a_state += value
    }
    return b_state
}
