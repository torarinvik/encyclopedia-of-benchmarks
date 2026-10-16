package game_of_life

import "core:c"

MAX_SIDE :: 32

@(export)
game_of_life :: proc "contextless" (input: [^]i64, length: c.size_t,
        output: [^]u8, output_capacity: c.size_t) -> i64 {
    if input == nil || length == 0 do return -1
    side_value := input[0]
    if side_value < 0 || side_value > MAX_SIDE do return -1
    side := c.size_t(side_value)
    cell_count := side * side
    if length != cell_count + 1 do return -1
    for index: c.size_t = 0; index < cell_count; index += 1 {
        if input[index + 1] != 0 && input[index + 1] != 1 do return -1
    }
    if output_capacity < cell_count || (cell_count != 0 && output == nil) do return -2

    for row: c.size_t = 0; row < side; row += 1 {
        for column: c.size_t = 0; column < side; column += 1 {
            neighbors := 0
            for row_delta := -1; row_delta <= 1; row_delta += 1 {
                for column_delta := -1; column_delta <= 1; column_delta += 1 {
                    if row_delta == 0 && column_delta == 0 do continue
                    neighbor_row := i64(row) + i64(row_delta)
                    neighbor_column := i64(column) + i64(column_delta)
                    if neighbor_row >= 0 && neighbor_row < side_value &&
                        neighbor_column >= 0 && neighbor_column < side_value &&
                        input[1 + c.size_t(neighbor_row) * side + c.size_t(neighbor_column)] == 1 {
                        neighbors += 1
                    }
                }
            }
            index := row * side + column
            alive := input[index + 1] == 1
            output[index] = u8((alive && (neighbors == 2 || neighbors == 3)) ||
                                (!alive && neighbors == 3))
        }
    }
    return i64(cell_count)
}
