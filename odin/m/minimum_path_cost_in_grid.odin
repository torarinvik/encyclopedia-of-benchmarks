package minimum_path_cost_in_grid

import "core:c"

@(export)
minimum_path_cost_in_grid :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
    if input == nil || length < 2 || input[0] < 1 || input[0] > 32 || input[1] < 1 || input[1] > 32 do return -1
    rows := int(input[0])
    columns := int(input[1])
    cells := rows * columns
    move_offset := 2 + cells
    if int(length) != move_offset + cells * columns do return -1
    for index := 0; index < cells; index += 1 {
        if input[2 + index] < 0 || input[2 + index] >= i64(cells) do return -1
    }
    for index := 0; index < cells * columns; index += 1 {
        if input[move_offset + index] < 1 || input[move_offset + index] > 100 do return -1
    }
    costs: [32]i64 = {}
    next_costs: [32]i64 = {}
    for row := 0; row < rows - 1; row += 1 {
        for target := 0; target < columns; target += 1 {
            next_costs[target] = 1_000_000_000
        }
        for column := 0; column < columns; column += 1 {
            value := int(input[2 + row * columns + column])
            base := costs[column] + i64(value)
            for target := 0; target < columns; target += 1 {
                candidate := base + input[move_offset + value * columns + target]
                if candidate < next_costs[target] do next_costs[target] = candidate
            }
        }
        for column := 0; column < columns; column += 1 do costs[column] = next_costs[column]
    }
    minimum := i64(1_000_000_000)
    last_row := 2 + (rows - 1) * columns
    for column := 0; column < columns; column += 1 {
        candidate := costs[column] + input[last_row + column]
        if candidate < minimum do minimum = candidate
    }
    return minimum
}
