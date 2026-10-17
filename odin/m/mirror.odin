package mirror

import "core:c"

@(export)
mirror :: proc "c" (input: [^]i64, length: c.size_t, output: [^]u8, capacity: c.size_t) -> i64 {
    if input == nil || length < 1 || length > 257 do return -1
    if input[0] < 0 || input[0] > 256 do return -1
    n := int(input[0])
    if length != c.size_t(n + 1) do return -1
    for i := 0; i < n; i += 1 { if input[i + 1] < 1 || input[i + 1] > 127 do return -1 }
    if output == nil || capacity < c.size_t(n + 1) do return -2
    buffer: [257]u8 = {}
    for i := 0; i < n; i += 1 { buffer[i] = u8(input[i + 1]) }
    buffer[n] = 0
    logical_length := 0
    for buffer[logical_length] != 0 { logical_length += 1 }
    if logical_length > 0 {
        left := 0
        right := logical_length - 1
        for left <= right {
            temporary := buffer[left]
            buffer[left] = buffer[right]
            buffer[right] = temporary
            left += 1
            if right == 0 do break
            right -= 1
        }
    }
    for i := 0; i < n; i += 1 { output[i] = buffer[i] }
    output[n] = 0
    return i64(n)
}
