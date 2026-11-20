package linear_partition_minimax

import "core:c"

lpm_feasible :: proc(input: [^]i64, n, groups: int, limit: i64) -> bool {
    used_groups := 1
    current_sum: i64 = 0
    for i in 0..<n {
        value := input[i + 2]
        if current_sum + value > limit {
            used_groups += 1
            current_sum = value
            if used_groups > groups do return false
        } else {
            current_sum += value
        }
    }
    return true
}

@(export)
linear_partition_minimax :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
    if input == nil || length < 3 || length > 35 do return -1
    if input[0] < 1 || input[0] > 32 || input[1] < 1 || input[1] > input[0] do return -1
    n := int(input[0])
    groups := int(input[1])
    if length != c.size_t(n + 2) do return -1

    low: i64 = 0
    upper: i64 = 0
    for i in 0..<n {
        value := input[i + 2]
        if value < 0 || value > 1000 do return -1
        if value > low { low = value }
        upper += value
    }
    for low < upper {
        middle := low + (upper - low) / 2
        if lpm_feasible(input, n, groups, middle) { upper = middle }
        else { low = middle + 1 }
    }
    return low
}
