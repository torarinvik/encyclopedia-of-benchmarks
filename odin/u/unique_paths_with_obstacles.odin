package unique_paths_with_obstacles

import "core:c"

MAX_ROWS :: 20
MAX_COLUMNS :: 20

// Count right/down paths through a packed obstacle grid.
@(export)
unique_paths_with_obstacles :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
    if length < 2 || input == nil do return -1
    rows_value, columns_value := input[0], input[1]
    if rows_value < 1 || rows_value > MAX_ROWS ||
       columns_value < 1 || columns_value > MAX_COLUMNS { return -1 }
    rows, columns := int(rows_value), int(columns_value)
    if int(length) != 2 + rows * columns { return -1 }

    paths: [MAX_COLUMNS]u64 = {}
    paths[0] = 1
    cells_seen := u64(0)
    left := u64(0)
    index := 2
    for index < int(length) {
        left = 0
        for column := 0; column < columns; column += 1 {
            obstacle := u64(input[index])
            cells_seen |= obstacle
            left = left + paths[column] if obstacle == 0 else 0
            paths[column] = left
            index += 1
        }
    }
    if cells_seen > 1 do return -1
    return i64(left)
}
