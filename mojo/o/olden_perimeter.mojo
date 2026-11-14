from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

fn perimeter_visit(x: Int64, y: Int64, span: Int64, grid: Int64, edge: Int64) -> Int64:
    if span == 1:
        var result: Int64 = 0
        if x == 0: result += edge
        if x + 1 == grid: result += edge
        if y == 0: result += edge
        if y + 1 == grid: result += edge
        return result
    let half = span // 2
    return perimeter_visit(x, y, half, grid, edge) + perimeter_visit(x + half, y, half, grid, edge) + perimeter_visit(x, y + half, half, grid, edge) + perimeter_visit(x + half, y + half, half, grid, edge)

@export("olden_perimeter")
fn olden_perimeter(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length != 1: return -1
    let level = input[0]
    if level < 9 or level > 11: return -1
    let grid = Int64(1) << Int(level)
    return perimeter_visit(0, 0, grid, grid, 4096 // grid)
