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

    costs: [100]i64 = {}
    next_costs: [100]i64 = {}
    for column := 0; column < n; column += 1 do costs[column] = input[1 + column]
    for row := 1; row < n; row += 1 {
        for column := 0; column < n; column += 1 {
            best := costs[column]
            if column > 0 && costs[column - 1] < best do best = costs[column - 1]
            if column + 1 < n && costs[column + 1] < best do best = costs[column + 1]
            next_costs[column] = best + input[1 + row * n + column]
        }
        for column := 0; column < n; column += 1 do costs[column] = next_costs[column]
    }
    minimum := costs[0]
    for column := 1; column < n; column += 1 {
        if costs[column] < minimum do minimum = costs[column]
    }
    return minimum
}
