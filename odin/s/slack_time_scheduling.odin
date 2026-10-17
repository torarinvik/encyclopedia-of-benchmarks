package slack_time_scheduling

import "core:c"

MAX_N :: 64
MAX_TIME :: 1000000

@(export, link_name="slack_time_scheduling")
slack_time_scheduling :: proc "c" (input: [^]i64, length: c.size_t,
    output: [^]u8, capacity: c.size_t) -> i64 {
    if input == nil || length < 1 || length > c.size_t(1 + 2 * MAX_N) do return -1
    if input[0] < 0 || input[0] > MAX_N do return -1
    n := int(input[0])
    if length != c.size_t(1 + 2 * n) do return -1
    slack: [MAX_N]i64
    order: [MAX_N]int
    for i := 0; i < n; i += 1 {
        execution := input[1 + 2 * i]
        deadline := input[2 + 2 * i]
        if execution < 0 || execution > MAX_TIME || deadline < 0 || deadline > MAX_TIME do return -1
        slack[i] = deadline - execution
        order[i] = i
    }
    bytes := c.size_t(8 * n)
    if output == nil || capacity < bytes do return -2
    for i := 1; i < n; i += 1 {
        key := order[i]
        j := i
        for j > 0 && slack[key] < slack[order[j - 1]] { order[j] = order[j - 1]; j -= 1 }
        order[j] = key
    }
    for i := 0; i < n; i += 1 {
        bits := u64(order[i])
        for byte := 0; byte < 8; byte += 1 { output[i*8+byte] = u8((bits >> (byte*8)) & 255) }
    }
    return i64(bytes)
}
