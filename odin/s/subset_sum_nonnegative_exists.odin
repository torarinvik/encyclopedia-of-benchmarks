package subset_sum_nonnegative_exists

import "core:c"

MAX_ITEMS :: 64
MAX_TARGET :: i64 = 4096
WIDTH :: 4097

@(export)
subset_sum_nonnegative_exists :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
    if input == nil || length == 0 || length > MAX_ITEMS + 1 do return -1
    target := input[0]
    if target < 0 || target > MAX_TARGET do return -1
    for index: c.size_t = 1; index < length; index += 1 {
        if input[index] < 0 || input[index] > MAX_TARGET do return -1
    }

    reachable: [WIDTH]bool = {}
    reachable[0] = true
    for index: c.size_t = 1; index < length; index += 1 {
        item := input[index]
        sum := target
        for sum >= item {
            if reachable[int(sum - item)] do reachable[int(sum)] = true
            sum -= 1
        }
    }
    if reachable[int(target)] do return 1
    return 0
}
