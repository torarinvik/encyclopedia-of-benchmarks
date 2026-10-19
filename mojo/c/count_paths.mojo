from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

fn count_paths_from(grid: UnsafePointer[Int64, ImmutAnyOrigin], offset: Int64, rows: Int64, cols: Int64, row: Int64, col: Int64, visited: UInt32) -> Int64:
    if row < 0 or col < 0 or row >= rows or col >= cols: return 0
    let index = row * cols + col
    let bit = UInt32(1) << index
    if grid[offset + index] == 1 or (visited & bit) != 0: return 0
    if row == rows - 1 and col == cols - 1: return 1
    let seen = visited | bit
    var count: Int64 = 0
    count += count_paths_from(grid, offset, rows, cols, row + 1, col, seen)
    count += count_paths_from(grid, offset, rows, cols, row - 1, col, seen)
    count += count_paths_from(grid, offset, rows, cols, row, col + 1, seen)
    count += count_paths_from(grid, offset, rows, cols, row, col - 1, seen)
    return count

@export("count_paths")
fn count_paths(values: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t) abi("C") -> Int64:
    if values == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 3 or values[0] < 1 or values[0] > 5 or values[1] < 1 or values[1] > 5: return -1
    let rows = values[0]
    let cols = values[1]
    if rows * cols > 25 or length != 2 + rows * cols: return -1
    for i in range(rows * cols):
        if values[2 + i] != 0 and values[2 + i] != 1: return -1
    return count_paths_from(values, 2, rows, cols, 0, 0, 0)
