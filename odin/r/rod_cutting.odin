package rod_cutting

import "core:c"

@(export)
rod_cutting :: proc "c" (values: [^]i64, length: c.size_t) -> i64 {
    if values == nil || length < 2 do return -1
    n_value := values[0]
    if n_value < 1 || n_value > 30 do return -1
    n := c.size_t(n_value)
    if length != n + 1 do return -1
    for i in 0..<n {
        if values[i + 1] < 1 || values[i + 1] > 1000 do return -1
    }
    profit: [31]i64 = {}
    for rod := 1; rod <= n; rod += 1 {
        best := i64(0)
        for cut := 1; cut <= rod; cut += 1 {
            candidate := values[cut] + profit[rod - cut]
            if candidate > best do best = candidate
        }
        profit[rod] = best
    }
    return profit[n]
}
