package functional_graph_cycle_brent

import "core:c"

@(export)
functional_graph_cycle_brent :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
    if input == nil || length < 3 || length > 67 do return -1
    n, start := input[0], input[1]
    if n < 1 || n > 64 || start < 0 || start >= n || length != c.size_t(n+2) do return -1
    for i := 0; i < int(n); i += 1 {
        if input[2+i] < 0 || input[2+i] >= n do return -1
    }
    checkpoint, moving := start, input[2+int(start)]
    power, period := i64(1), i64(1)
    for checkpoint != moving {
        if power == period { checkpoint = moving; power *= 2; period = 0 }
        moving = input[2+int(moving)]; period += 1
    }
    left, right := start, start
    for i := i64(0); i < period; i += 1 { right = input[2+int(right)] }
    tail := i64(0)
    for left != right {
        left = input[2+int(left)]; right = input[2+int(right)]; tail += 1
    }
    return 65 * tail + period
}
