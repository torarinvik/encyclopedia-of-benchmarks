package skytale_cipher

import "core:c"

MAX_INPUT_LENGTH :: 260
MAX_TEXT_LENGTH :: 256
MAX_KEY :: 256

@(export)
skytale_cipher :: proc "c" (input: [^]i64, length: c.size_t,
                               output: [^]u8, capacity: c.size_t) -> i64 {
    if input == nil || length < 3 || length > 260 do return -1
    if input[0] < 0 || input[0] > 1 || input[1] < 1 || input[1] > 256 || input[2] < 0 || input[2] > 256 do return -1
    mode := int(input[0])
    key := int(input[1])
    n := int(input[2])
    if length != c.size_t(3 + n) do return -1
    for i := 0; i < n; i += 1 { if input[3 + i] < 0 || input[3 + i] > 127 do return -1 }
    if output == nil || capacity < c.size_t(n) do return -2

    if mode == 0 {
        out := 0
        for row := 0; row < key; row += 1 {
            for position := row; position < n; position += key {
                output[out] = u8(input[3 + position])
                out += 1
            }
        }
    } else {
        starts: [256]int = {}
        used: [256]int = {}
        base := n / key
        extra := n % key
        for row := 1; row < key; row += 1 { starts[row] = starts[row - 1] + base; if row - 1 < extra { starts[row] += 1 } }
        for position := 0; position < n; position += 1 {
            row := position % key
            output[position] = u8(input[3 + starts[row] + used[row]])
            used[row] += 1
        }
    }
    return i64(n)
}
