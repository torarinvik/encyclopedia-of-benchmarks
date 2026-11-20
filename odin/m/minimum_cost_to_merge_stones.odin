package minimum_cost_to_merge_stones

import "core:c"

MAX_N :: 30
MAX_K :: 30
MAX_INPUT_LENGTH :: 33
DP_CELLS :: MAX_N * MAX_N * (MAX_K + 1)
INFINITY :: i64(1152921504606846976)

mcs_index :: proc(left, right, piles: int) -> int {
    return (left * MAX_N + right) * (MAX_K + 1) + piles
}

@(export)
minimum_cost_to_merge_stones :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
    if input == nil || length < 3 || length > MAX_INPUT_LENGTH do return -1
    if input[0] < 1 || input[0] > MAX_N || input[1] < 2 || input[1] > MAX_K do return -1
    n := int(input[0])
    merge_count := int(input[1])
    if length != c.size_t(n + 2) do return -1

    prefix: [MAX_N + 1]i64
    for i in 0..<n {
        stone := input[i + 2]
        if stone < 1 || stone > 100 do return -1
        prefix[i + 1] = prefix[i] + stone
    }
    if (n - 1) % (merge_count - 1) != 0 do return -1

    dp: [DP_CELLS]i64
    for i in 0..<DP_CELLS { dp[i] = INFINITY }
    for i in 0..<n { dp[mcs_index(i, i, 1)] = 0 }
    for interval_length in 2..=n {
        for left in 0..<(n - interval_length + 1) {
            right := left + interval_length - 1
            maximum_piles := if merge_count < interval_length { merge_count } else { interval_length }
            for piles in 2..=maximum_piles {
                best: i64 = INFINITY
                for cut in left..<right {
                    first := dp[mcs_index(left, cut, 1)]
                    rest := dp[mcs_index(cut + 1, right, piles - 1)]
                    if first < INFINITY && rest < INFINITY && first + rest < best { best = first + rest }
                }
                dp[mcs_index(left, right, piles)] = best
            }
            if interval_length >= merge_count {
                to_k := dp[mcs_index(left, right, merge_count)]
                if to_k < INFINITY { dp[mcs_index(left, right, 1)] = to_k + prefix[right + 1] - prefix[left] }
            }
        }
    }
    answer := dp[mcs_index(0, n - 1, 1)]
    if answer >= INFINITY do return -1
    return answer
}
