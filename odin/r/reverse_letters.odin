package reverse_letters

import "core:c"

@(export)
reverse_letters :: proc "c" (input: [^]i64, length: c.size_t, output: [^]u8, output_capacity: c.size_t) -> i64 {
    if input == nil || length < 1 do return -1
    if input[0] < 0 || input[0] > 256 do return -1
    n := int(input[0])
    if length != c.size_t(n + 1) do return -1
    for index := 0; index < n; index += 1 {
        value := input[index + 1]
        if value == 32 {
            if index == 0 || index + 1 == n || input[index] == 32 do return -1
        } else if value < 33 || value > 126 do return -1
    }
    if output == nil || output_capacity < c.size_t(n + 1) do return -2
    start := 0
    for start < n {
        ending := start
        for ending < n && input[ending + 1] != 32 { ending += 1 }
        for index := 0; index < ending - start + 1; index += 1 {
            output[start + index] = u8(input[ending - index + 1])
        }
        if ending < n do output[ending] = 32
        start = ending + 1
    }
    output[n] = 0
    return i64(n)
}
