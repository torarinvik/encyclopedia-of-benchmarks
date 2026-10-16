package pairs_with_given_sum

import "core:c"

@(export)
pairs_with_given_sum :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
    if input == nil || length == 0 || length > 257 {
        return -2
    }
    for index := c.size_t(0); index < length; index += 1 {
        if input[index] < -2147483648 || input[index] > 2147483647 {
            return -2
        }
    }
    target := input[0]
    value_count := length - 1
    pairs: i64 = 0
    for left := c.size_t(0); left < value_count; left += 1 {
        for right := left + 1; right < value_count; right += 1 {
            if input[left+1]+input[right+1] == target {
                pairs += 1
            }
        }
    }
    return pairs
}
