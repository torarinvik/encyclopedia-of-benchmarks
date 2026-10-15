package count_nice_subarrays

import "core:c"

MAX_LENGTH :: 4096

@(export)
count_nice_subarrays :: proc "c" (values: [^]i64, length: c.size_t) -> i64 {
    if values == nil || length < 2 || values[0] < 0 || values[0] > MAX_LENGTH || values[1] < 1 || values[1] > MAX_LENGTH do return -1
    n, k := int(values[0]), int(values[1])
    if length != c.size_t(n + 2) do return -1
    for i := 0; i < n; i += 1 {
        if values[i + 2] < -2147483648 || values[i + 2] > 2147483647 do return -1
    }
    memo: [MAX_LENGTH]i32 = {}
    left, odd_count := 0, 0
    result := i64(0)
    for right := 0; right < n; right += 1 {
        if (i32(values[right + 2]) & 1) == 1 do odd_count += 1
        if odd_count > k {
            left += int(memo[left])
            odd_count -= 1
        }
        if odd_count == k {
            if memo[left] == 0 {
                even_count, temp := 0, left
                for (i32(values[temp + 2]) & 1) == 0 {
                    even_count += 1
                    temp += 1
                }
                memo[left] = i32(even_count + 1)
            }
            result += i64(memo[left])
        }
    }
    return result
}
