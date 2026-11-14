# Independent bounded Connect Four negamax profile; see package SOURCE_RIGHTS.md
# for John Tromp's original notices and redistribution restrictions.
from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

fn fh_wins(board: InlineArray[Int, 42], column: Int, row: Int, side: Int) -> Bool:
    let dx = InlineArray[Int, 4](1, 0, 1, 1)
    let dy = InlineArray[Int, 4](0, 1, 1, -1)
    for direction in range(4):
        var count = 1
        for sign_index in range(2):
            let sign = -1 if sign_index == 0 else 1
            for step in range(1, 4):
                let x = column + sign * step * dx[direction]
                let y = row + sign * step * dy[direction]
                if x < 0 or x >= 7 or y < 0 or y >= 6: break
                if board[y * 7 + x] != side: break
                count += 1
        if count >= 4: return True
    return False

fn fh_search(inout board: InlineArray[Int, 42], inout heights: InlineArray[Int, 7],
             side: Int, remaining: Int, alpha_in: Int, beta: Int) -> Int:
    if remaining == 0: return 0
    let columns = InlineArray[Int, 7](3, 2, 4, 1, 5, 0, 6)
    var alpha = alpha_in
    var best = -3
    for i in range(7):
        let column = columns[i]
        let row = heights[column]
        if row == 6: continue
        board[row * 7 + column] = side
        heights[column] = row + 1
        var value = 2
        if not fh_wins(board, column, row, side):
            let opponent = 2 if side == 1 else 1
            value = -fh_search(board, heights, opponent, remaining - 1, -beta, -alpha)
        heights[column] = row
        board[row * 7 + column] = 0
        if value > best: best = value
        if value > alpha: alpha = value
        if alpha >= beta: break
    return best

@export("fhourstones_exact")
fn fhourstones_exact(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 2 or length > 42: return -1
    let raw = input[0]
    if raw < 36 or raw > 41 or Int(length) != Int(raw) + 1: return -1
    let count = Int(raw)
    var board = InlineArray[Int, 42](fill=0)
    var heights = InlineArray[Int, 7](fill=0)
    for turn in range(count):
        let column_raw = input[turn + 1]
        if column_raw < 0 or column_raw >= 7: return -1
        let column = Int(column_raw)
        let row = heights[column]
        if row >= 6: return -1
        let side = 1 if turn % 2 == 0 else 2
        board[row * 7 + column] = side
        heights[column] = row + 1
        if fh_wins(board, column, row, side): return -1
    let side = 1 if count % 2 == 0 else 2
    return Int64(fh_search(board, heights, side, 42 - count, -3, 3))
