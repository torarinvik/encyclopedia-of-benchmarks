from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

alias MAX_CELLS = 64
alias MAX_INPUT = 68

@export("recursive_backtracker_maze_generation")
fn recursive_backtracker_maze_generation(
    input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
    output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t,
) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 4 or length > c_size_t(MAX_INPUT): return -1
    let rows_word = input[0]
    let cols_word = input[1]
    let start_word = input[2]
    let draw_count = input[3]
    if rows_word < 1 or rows_word > 64 or cols_word < 1 or cols_word > 64: return -1
    let rows = Int(rows_word)
    let cols = Int(cols_word)
    let cells = rows * cols
    if cells > MAX_CELLS or start_word < 0 or start_word >= Int64(cells) or
        draw_count != Int64(cells - 1) or length != c_size_t(4 + cells - 1): return -1
    for draw in range(cells - 1):
        if input[4 + draw] < 0 or input[4 + draw] > 3: return -1

    var visited = InlineArray[Bool, MAX_CELLS](fill=False)
    var walls = InlineArray[UInt8, MAX_CELLS](fill=15)
    var stack = InlineArray[Int, MAX_CELLS](fill=0)
    var depth = 1
    var cursor = 0
    stack[0] = Int(start_word)
    visited[stack[0]] = True
    while depth > 0:
        let cell = stack[depth - 1]
        let row = cell // cols
        let col = cell % cols
        var next_cells = InlineArray[Int, 4](fill=0)
        var directions = InlineArray[Int, 4](fill=0)
        var count = 0
        if row > 0 and not visited[cell - cols]:
            next_cells[count] = cell - cols
            directions[count] = 0
            count += 1
        if col + 1 < cols and not visited[cell + 1]:
            next_cells[count] = cell + 1
            directions[count] = 1
            count += 1
        if row + 1 < rows and not visited[cell + cols]:
            next_cells[count] = cell + cols
            directions[count] = 2
            count += 1
        if col > 0 and not visited[cell - 1]:
            next_cells[count] = cell - 1
            directions[count] = 3
            count += 1
        if count == 0:
            depth -= 1
            continue
        if cursor >= cells - 1: return -1
        let choice = Int(input[4 + cursor])
        cursor += 1
        if choice >= count: return -1
        let next = next_cells[choice]
        let direction = directions[choice]
        visited[next] = True
        walls[cell] = walls[cell] & UInt8(15 - (1 << direction))
        walls[next] = walls[next] & UInt8(15 - (1 << ((direction + 2) & 3)))
        stack[depth] = next
        depth += 1
    if cursor != cells - 1: return -1
    for cell in range(cells):
        if not visited[cell]: return -1
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(cells): return -2
    for cell in range(cells): output[cell] = walls[cell]
    Int64(cells)
