package minimum_falling_path_sum

import "core:c"

@(export)
minimum_falling_path_sum :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
    if input == nil || length < 1 || input[0] < 1 || input[0] > 100 do return -10001
    n := int(input[0])
    if int(length) != 1 + n * n do return -10001
    for index := 0; index < n * n; index += 1 {
        if input[1 + index] < -100 || input[1 + index] > 100 do return -10001
    }

    costs: [102]u16 = {}
    next_costs: [100]u16 = {}
    costs[0] = 32768
    costs[n + 1] = 32768
    for column := 0; column < n; column += 1 {
        costs[column + 1] = u16(input[1 + column] + 100)
    }
    for row := 1; row < n; row += 1 {
        for column := 0; column < n; column += 1 {
            best := min(costs[column], costs[column + 1], costs[column + 2])
            next_costs[column] = best + u16(input[1 + row * n + column] + 100)
        }
        for column := 0; column < n; column += 1 {
            costs[column + 1] = next_costs[column]
        }
    }
    minimum := costs[1]
    for column := 1; column < n; column += 1 {
        minimum = min(minimum, costs[column + 1])
    }
    return i64(minimum) - 100 * i64(n)
}
