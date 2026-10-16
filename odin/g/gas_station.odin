package gas_station

import "core:c"

@(export)
gas_station :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
    if input == nil || length < 1 do return -2
    n64 := input[0]; if n64 < 0 || n64 > 128 do return -2
    n := usize(n64); if length != c.size_t(2*n+1) do return -2
    for i: usize = 0; i < 2*n; i += 1 { if input[i+1] < 0 || input[i+1] > 1000000 do return -2 }
    total, current: i64 = 0, 0
    start: usize = 0
    for i: usize = 0; i < n; i += 1 {
        net := input[1+i]-input[1+n+i]
        total += net; current += net
        if current < 0 { start=i+1; current=0 }
    }
    if total < 0 do return -1
    return i64(start)
}
