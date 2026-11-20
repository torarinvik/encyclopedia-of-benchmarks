package hofstadter_q_sequence

import "core:c"

MAX_INDEX :: i64(128)
MAX_PARSEABLE_LENGTH :: 2

@(export)
hofstadter_q_sequence :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
    if input == nil || length < 1 || length > c.size_t(MAX_PARSEABLE_LENGTH) do return -1
    if length != 1 || input[0] < 1 || input[0] > MAX_INDEX do return -1

    target := int(input[0])
    q: [129]i64 = {}
    q[1] = 1
    if target >= 2 do q[2] = 1
    for n := 3; n <= target; n += 1 {
        left := i64(n) - q[n - 1]
        right := i64(n) - q[n - 2]
        if left < 1 || right < 1 || left >= i64(n) || right >= i64(n) do return -1
        q[n] = q[int(left)] + q[int(right)]
    }
    return q[target]
}
