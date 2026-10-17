package median_search2

import "core:c"

MAX_NODES :: 128
MAX_INPUT_LENGTH :: 129

put_i32_le :: proc "contextless" (output: [^]u8, offset: int, value: i32) {
    bits := u32(value)
    for byte := 0; byte < 4; byte += 1 { output[offset+byte] = u8(bits >> u32(8*byte)) }
}

@(export)
median_search2 :: proc "c" (input: [^]i64, length: c.size_t,
        output: [^]u8, capacity: c.size_t) -> i64 {
    if input == nil || length < 1 || length > c.size_t(MAX_INPUT_LENGTH) do return -1
    if input[0] < 0 || input[0] > MAX_NODES do return -1
    count := int(input[0])
    if int(length) != count + 1 do return -1
    for i := 0; i < count; i += 1 {
        if input[i+1] < -2_147_483_648 || input[i+1] > 2_147_483_647 do return -1
    }

    next: [MAX_NODES]i32
    for i := 0; i < count; i += 1 {
        if i+1 < count do next[i] = i32(i+1)
        else do next[i] = -1
    }
    found: i32 = 0
    median_index: i32 = -1
    if count > 0 {
        slow: i32 = 0
        fast: i32 = 0
        for next[int(fast)] >= 0 && next[int(next[int(fast)])] >= 0 {
            slow = next[int(slow)]
            fast = next[int(next[int(fast)])]
        }
        if next[int(fast)] >= 0 do median_index = next[int(slow)]
        else do median_index = slow
        found = 1
    }
    if output == nil || capacity < 8 do return -2
    buffer: [8]u8
    put_i32_le(&buffer[0], 0, found)
    put_i32_le(&buffer[0], 4, median_index)
    for i := 0; i < 8; i += 1 { output[i] = buffer[i] }
    return 8
}
