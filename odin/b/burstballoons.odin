package burstballoons

import "core:c"

@(export)
burstballoons :: proc "c" (values: [^]i64, length: c.size_t) -> i64 {
    if length > 128 do return -1
    for index := 0; index < int(length); index += 1 {
        if values[index] < 0 || values[index] > 1000 do return -1
    }
    if length == 0 do return 0

    padded: [130]i64
    dp: [130][130]i64
    padded[0] = 1
    padded[int(length)+1] = 1
    for index := 0; index < int(length); index += 1 {
        padded[index+1] = values[index]
    }
    for span := 1; span <= int(length); span += 1 {
        for left := 1; left+span-1 <= int(length); left += 1 {
            right := left+span-1
            best := i64(0)
            for last := left; last <= right; last += 1 {
                coins := dp[left][last-1] + dp[last+1][right]
                    + padded[left-1] * padded[last] * padded[right+1]
                if coins > best do best = coins
            }
            dp[left][right] = best
        }
    }
    return dp[1][int(length)]
}
