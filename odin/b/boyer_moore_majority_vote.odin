package boyer_moore_majority_vote

import "core:c"

// Return a strict majority element, or -1 if none exists.
@(export)
boyer_moore_majority_vote :: proc "c" (values: [^]i64, length: c.size_t) -> i64 {
    if length < 1 || length > 256 do return -1
    candidate: i64 = 0
    balance := 0
    for index := 0; index < int(length); index += 1 {
        if balance == 0 do candidate = values[index]
        if values[index] == candidate { balance += 1 } else { balance -= 1 }
    }
    occurrences := 0
    for index := 0; index < int(length); index += 1 {
        if values[index] == candidate do occurrences += 1
    }
    if occurrences > int(length) / 2 do return candidate
    return -1
}
