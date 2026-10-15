package longest_common_substring

import "core:c"

MAX_LENGTH :: 256

@(export)
longest_common_substring :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
    if input == nil || length < 2 || input[0] < 0 || input[0] > MAX_LENGTH do return -1
    first_length := int(input[0])
    if first_length + 2 > int(length) || input[first_length + 1] < 0 || input[first_length + 1] > MAX_LENGTH do return -1
    second_length := int(input[first_length + 1])
    if int(length) != first_length + second_length + 2 do return -1
    first := 1; second := first_length + 2
    for i := 0; i < first_length; i += 1 { if input[first+i] < 32 || input[first+i] > 126 do return -1 }
    for j := 0; j < second_length; j += 1 { if input[second+j] < 32 || input[second+j] > 126 do return -1 }
    dp: [MAX_LENGTH+1]i64
    best: i64 = 0
    for i := 1; i <= first_length; i += 1 {
        for j := second_length; j > 0; j -= 1 {
            if input[first+i-1] == input[second+j-1] { dp[j] = dp[j-1] + 1; if dp[j] > best do best = dp[j] }
            else { dp[j] = 0 }
        }
    }
    return best
}
