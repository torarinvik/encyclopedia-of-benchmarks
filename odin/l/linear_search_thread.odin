package linear_search_thread

import "core:c"

MAX_COUNT :: i64(64)
MAX_INPUT_LENGTH :: c.size_t(69)
I32_MIN :: i64(-2_147_483_648)
I32_MAX :: i64(2_147_483_647)

@(export)
linear_search_thread :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
    if input == nil || length < 4 || length > MAX_INPUT_LENGTH do return -1
    count_arg, left, right, target := input[0], input[1], input[2], input[3]
    if count_arg < 1 || count_arg > MAX_COUNT || length != c.size_t(count_arg) + 4 do return -1
    if left < 0 || left > right || right > count_arg || target < I32_MIN || target > I32_MAX do return -1
    count := c.size_t(count_arg)
    for index := c.size_t(0); index < count; index += 1 {
        value := input[4 + index]
        if value < I32_MIN || value > I32_MAX do return -1
    }
    for index := c.size_t(left); index < c.size_t(right); index += 1 {
        if input[4 + index] == target do return 1
    }
    return 0
}
