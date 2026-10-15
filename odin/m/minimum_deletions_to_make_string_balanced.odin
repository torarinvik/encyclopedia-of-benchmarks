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
		next_a := a_state
		if value == 1 do next_a += 1
		b_with_a := b_state
		if value == 0 do b_with_a += 1
        next_b := a_state
        if b_with_a < next_b do next_b = b_with_a
        a_state = next_a
        b_state = next_b
    }
    if a_state < b_state do return a_state
    return b_state
}
