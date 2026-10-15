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
    for index := 2; index < int(length); index += 1 {
        if input[index] != 0 && input[index] != 1 { return -1 }
    }

    paths: [MAX_COLUMNS]i64 = {}
    paths[0] = 1
    for row := 0; row < rows; row += 1 {
        for column := 0; column < columns; column += 1 {
            obstacle := input[2 + row * columns + column]
            if obstacle == 1 { paths[column] = 0 }
            else if column > 0 { paths[column] += paths[column - 1] }
        }
    }
    return paths[columns - 1]
}
