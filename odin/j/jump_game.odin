package jump_game

import "core:c"

@(export)
jump_game :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
    if input == nil do return -2
    if length < 2 || length > 1025 || input[0] < 1 || input[0] > 1024 || int(length) != int(input[0]) + 1 do return -2
    n := int(input[0])
    for i := 0; i < n; i += 1 {
        if input[i + 1] < 0 || input[i + 1] > 1000000 do return -2
    }
    last_pos := n - 1
    for i := n; i > 0; i -= 1 {
        index := i - 1
        if index + int(input[index + 1]) >= last_pos do last_pos = index
    }
    return 1 if last_pos == 0 else 0
}
