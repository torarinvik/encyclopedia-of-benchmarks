package stock_span_problem

import "core:c"

@(export)
stock_span_problem :: proc "c" (input: [^]i64, length: c.size_t,
    output: [^]u8, capacity: c.size_t) -> i64 {
    if input == nil || length < 2 || length > 66 do return -1
    count_value := input[0]
    if count_value < 1 || count_value > 64 do return -1
    count := int(count_value)
    if length != c.size_t(count + 1) do return -1
    for day := 0; day < count; day += 1 {
        price := input[day + 1]
        if price < -2_147_483_648 || price > 2_147_483_647 do return -1
    }

    output_bytes := count * 8
    if output == nil || capacity < c.size_t(output_bytes) do return -2
    decreasing: [64]int = {}
    top := 0
    for day := 0; day < count; day += 1 {
        price := input[day + 1]
        for top > 0 && input[decreasing[top - 1] + 1] <= price { top -= 1 }
        span := day + 1
        if top > 0 { span = day - decreasing[top - 1] }
        encoded := u64(span)
        for byte := 0; byte < 8; byte += 1 {
            output[day * 8 + byte] = u8((encoded >> (8 * byte)) & 255)
        }
        decreasing[top] = day
        top += 1
    }
    return count_value
}
