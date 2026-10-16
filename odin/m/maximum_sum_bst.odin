package maximum_sum_bst

import "core:c"

@(export)
maximum_sum_bst :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
    empty_min: i64 = 1_000_001
    if input == nil || length < 1 || length > 32 do return -1
    if input[0] < 0 || input[0] > 31 || length != c.size_t(input[0]) + 1 do return -1
    count := int(input[0])
    for i := 0; i < count; i += 1 {
        if input[i + 1] < -1 || input[i + 1] > 1_000_000 do return -1
        if input[i + 1] != -1 && i > 0 && input[(i - 1) / 2 + 1] == -1 do return -1
    }
    if count == 0 do return 0
    valid: [31]bool = {}
    subtree_min: [31]i64 = {}
    subtree_max: [31]i64 = {}
    subtree_sum: [31]i64 = {}
    best: [31]i64 = {}
    remaining := count
    for remaining > 0 {
        remaining -= 1
        i := remaining
        if input[i + 1] == -1 {
            valid[i] = true; subtree_min[i] = empty_min; subtree_max[i] = -1
            continue
        }
        left := 2 * i + 1; right := left + 1
        left_valid := left >= count || valid[left]
        right_valid := right >= count || valid[right]
        left_max: i64 = -1; right_min := empty_min; left_min := empty_min; right_max: i64 = -1
        left_sum: i64 = 0; right_sum: i64 = 0; left_best: i64 = 0; right_best: i64 = 0
        if left < count { left_max = subtree_max[left]; left_min = subtree_min[left]; left_sum = subtree_sum[left]; left_best = best[left] }
        if right < count { right_min = subtree_min[right]; right_max = subtree_max[right]; right_sum = subtree_sum[right]; right_best = best[right] }
        value := input[i + 1]
        if left_valid && right_valid && left_max < value && value < right_min {
            valid[i] = true
            subtree_min[i] = min(left_min, value)
            subtree_max[i] = max(right_max, value)
            subtree_sum[i] = left_sum + right_sum + value
            best[i] = max(subtree_sum[i], left_best, right_best)
        } else {
            best[i] = max(left_best, right_best)
        }
    }
    return best[0]
}
