package random_permutation_cycle_cap_count

import "core:c"

@(export)
random_permutation_cycle_cap_count :: proc "c" (input: [^]i64, input_length: c.size_t) -> i64 {
    if input == nil || input_length != 2 do return -1
    n, cap := input[0], input[1]
    if n < 1 || n > 20 || cap < 1 || cap > n do return -1

    counts: [21]i64 = {}
    counts[0] = 1
    for size := 1; size <= int(n); size += 1 {
        total: i64 = 0
        cycle_choices: i64 = 1
        limit := size
        if int(cap) < limit do limit = int(cap)
        for cycle_length := 1; cycle_length <= limit; cycle_length += 1 {
            if cycle_length > 1 do cycle_choices *= i64(size - cycle_length + 1)
            total += cycle_choices * counts[size - cycle_length]
        }
        counts[size] = total
    }
    return counts[int(n)]
}
