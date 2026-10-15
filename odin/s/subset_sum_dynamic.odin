package subset_sum_dynamic

import "core:c"

MAX_ITEMS :: 16
WIDTH :: 801
STATES :: (MAX_ITEMS + 1) * WIDTH

subset_sum_dynamic_search :: proc "contextless" (input: [^]i64, item_count, index: int,
        remaining: i64, memo: [^]i64) -> i64 {
    if remaining == 0 do return 1
    if index == item_count do return 0
    state := index * WIDTH + int(remaining + 400)
    if memo[state] != -2 do return memo[state]
    result := subset_sum_dynamic_search(input, item_count, index + 1,
        remaining - input[index + 1], memo)
    if result == 0 do result = subset_sum_dynamic_search(input, item_count, index + 1, remaining, memo)
    memo[state] = result
    return result
}

@(export)
subset_sum_dynamic :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
    if input == nil || length == 0 || length > MAX_ITEMS + 1 do return -1
    target := input[0]
    if target < -80 || target > 80 do return -1
    for index: c.size_t = 1; index < length; index += 1 {
        if input[index] < -20 || input[index] > 20 do return -1
    }
    memo: [STATES]i64
    for index in 0 ..< STATES do memo[index] = -2
    return subset_sum_dynamic_search(input, int(length) - 1, 0, target, &memo[0])
}
