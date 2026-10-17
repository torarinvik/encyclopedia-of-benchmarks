package job_sequencing

import "core:c"

MAX_JOBS :: 32
MAX_INPUT_LENGTH :: 98
MAX_PROFIT :: i64(1_000_000)

@(export)
job_sequencing :: proc "c" (input: [^]i64, length: c.size_t, output: [^]u8, capacity: c.size_t) -> i64 {
    if input == nil || length < 4 || length > MAX_INPUT_LENGTH do return -1
    if input[0] < 1 || input[0] > MAX_JOBS do return -1
    n := int(input[0])
    if length != c.size_t(1 + 3 * n) do return -1
    seen: [128]u8 = {}
    previous_profit := MAX_PROFIT + 1
    for i := 0; i < n; i += 1 {
        base := 1 + 3 * i
        id, deadline, profit := input[base], input[base + 1], input[base + 2]
        letter := (id >= 65 && id <= 90) || (id >= 97 && id <= 122)
        if !letter || seen[int(id)] != 0 || deadline < 1 || deadline > i64(n) || profit < 1 || profit > MAX_PROFIT || profit >= previous_profit do return -1
        seen[int(id)] = 1
        previous_profit = profit
    }
    slots: [MAX_JOBS]u8 = {}
    total_profit := i64(0)
    for i := 0; i < n; i += 1 {
        base := 1 + 3 * i
        deadline := int(input[base + 1])
        for remaining := deadline; remaining > 0; remaining -= 1 {
            slot := remaining - 1
            if slots[slot] == 0 { slots[slot] = u8(input[base]); total_profit += input[base + 2]; break }
        }
    }
    count := 0
    for slot := 0; slot < n; slot += 1 { if slots[slot] != 0 { count += 1 } }
    required := 9 + count
    if output == nil || capacity < c.size_t(required) do return -2
    output[0] = u8(count)
    for byte := 0; byte < 8; byte += 1 { output[1 + byte] = u8((u64(total_profit) >> (8 * byte)) & 255) }
    written := 9
    for slot := 0; slot < n; slot += 1 { if slots[slot] != 0 { output[written] = slots[slot]; written += 1 } }
    return i64(required)
}
