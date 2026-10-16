package damm

import "core:c"

MAX_DIGITS :: 256
TABLE: [100]i64 = {0, 3, 1, 7, 5, 9, 8, 6, 4, 2, 7, 0, 9, 2, 1, 5, 4, 8, 6, 3, 4, 2, 0, 6, 8, 7, 1, 3, 5, 9, 1, 7, 5, 0, 9, 8, 3, 4, 2, 6, 6, 1, 2, 3, 0, 4, 5, 9, 7, 8, 3, 6, 7, 4, 2, 0, 9, 5, 8, 1, 5, 8, 6, 9, 7, 2, 0, 1, 3, 4, 8, 9, 4, 5, 3, 6, 2, 0, 1, 7, 9, 4, 3, 8, 6, 1, 7, 2, 0, 5, 2, 5, 8, 1, 4, 3, 6, 7, 9, 0}

@(export)
damm :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
    if input == nil || length < 3 || length > c.size_t(MAX_DIGITS + 2) do return -1
    mode, n := input[0], input[1]
    if (mode != 0 && mode != 1) || n < 1 || n > MAX_DIGITS || length != c.size_t(n + 2) do return -1
    state := 0
    for index := 0; index < int(n); index += 1 {
        digit := input[index + 2]
        if digit < 0 || digit > 9 do return -1
        state = int(TABLE[state * 10 + int(digit)])
    }
    if mode == 0 { if state == 0 { return 1 }; return 0 }
    return i64(state)
}
