package unique_paths

// Count right-and-down paths with one row of dynamic programming.
@(export)
unique_paths :: proc "c" (rows, columns: u64) -> i64 {
    if rows == 0 || columns == 0 || rows > 34 || columns > 34 do return -1
    width := min(rows, columns)
    height := max(rows, columns)
    paths: [34]i64
    for column: u64 = 0; column < width; column += 1 {
        paths[column] = 1
    }
    for row: u64 = 1; row < height; row += 1 {
        for column: u64 = 1; column < width; column += 1 {
            paths[column] += paths[column - 1]
        }
    }
    return paths[width - 1]
}
