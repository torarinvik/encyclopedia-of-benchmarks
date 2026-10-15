package online_stock_span

import "core:c"

@(export)
online_stock_span :: proc "c" (input: [^]i64, length: c.size_t,
                                output: [^]u8, output_capacity: c.size_t) -> i64 {
    if input == nil || length < 2 || input[0] < 1 || input[0] > 4095 do return -1
    count := int(input[0])
    if int(length) != count + 1 do return -1
    for day := 0; day < count; day += 1 {
        if input[day + 1] < 1 || input[day + 1] > 100000 do return -1
    }
    output_bytes := count * 8
    if int(output_capacity) < output_bytes || output == nil do return -2

    decreasing: [4095]int = {}
    top := 0
    for day := 0; day < count; day += 1 {
        price := input[day + 1]
        for top > 0 && input[decreasing[top - 1] + 1] <= price {
            top -= 1
        }
        span := day + 1
        if top > 0 do span = day - decreasing[top - 1]
        encoded := u64(span)
        for byte := 0; byte < 8; byte += 1 {
			output[day * 8 + byte] = u8((encoded >> u64(byte * 8)) & 255)
        }
        decreasing[top] = day
        top += 1
    }
    return i64(count)
}
