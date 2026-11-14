# Independent implementation of the documented FreeBench search profile.
from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

fn fm_score(board: InlineArray[Int, 42]) -> Int:
    var score = 0
    for player in range(1, 3):
        let sign = -1 if player == 1 else 1
        for n in range(2, 5):
            let weight = 5 if n == 2 else (20 if n == 3 else 1000)
            # Vertical masks have 21 possible starting offsets. For short
            # patterns the opposing player must not occupy the four-bit mask.
            for start in range(21):
                var present = True
                var open_line = True
                for k in range(4):
                    let square = start + 7 * k
                    if k < n and board[square] != player: present = False
                    if board[square] != 0 and board[square] != player: open_line = False
                if present and (n == 4 or open_line): score += sign * weight
            # The source scans horizontal and diagonal masks with a stride
            # of six, even though the board itself has seven columns.
            for row in range(6):
                for col in range(8 - n):
                    var present = True
                    for k in range(n):
                        if board[row * 6 + col + k] != player: present = False
                    if present: score += sign * weight
            for row in range(3):
                for col in range(4):
                    var rising = True
                    var falling = True
                    for k in range(n):
                        let up = row * 6 + col + 8 * k
                        let down = row * 6 + col + 3 + 6 * k
                        if up >= 42:
                            rising = False
                        elif board[up] != player:
                            rising = False
                        if down >= 42:
                            falling = False
                        elif board[down] != player:
                            falling = False
                    if rising: score += sign * weight
                    if falling: score += sign * weight
    return score

fn fm_win(board: InlineArray[Int, 42], column: Int, row: Int, player: Int) -> Bool:
    let dx = InlineArray[Int, 4](1, 0, 1, 1)
    let dy = InlineArray[Int, 4](0, 1, 1, -1)
    for direction in range(4):
        var count = 1
        for side in range(2):
            let sign = -1 if side == 0 else 1
            for step in range(1, 4):
                let x = column + sign * step * dx[direction]
                let y = row + sign * step * dy[direction]
                if x < 0 or x >= 7 or y < 0 or y >= 6: break
                if board[y * 7 + x] != player: break
                count += 1
        if count >= 4: return True
    return False

fn fm_search(inout board: InlineArray[Int, 42], inout heights: InlineArray[Int, 7],
             player: Int, level: Int, depth: Int, mode: Int, alpha: Int, beta: Int) -> Int:
    if level >= depth: return fm_score(board)
    var best = -100000 if player == 2 else 100000
    for col in range(7):
        let row = heights[col]
        if row == 6: continue
        board[row * 7 + col] = player
        heights[col] = row + 1
        let value = fm_search(board, heights, 3 - player, level + 1, depth, mode,
                              best if player == 2 else alpha, beta if player == 2 else best)
        heights[col] = row
        board[row * 7 + col] = 0
        if player == 2:
            if value > best: best = value
            if mode == 2 and best > beta: return best
        else:
            if value <= best: best = value
            if mode == 2 and best < alpha: return best
    return best

@export("fourinarow_minimax")
fn fourinarow_minimax(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 4 or length > 24: return -1
    let depth = input[0]
    let mode = input[1]
    let player = input[2]
    let count = input[3]
    if depth < 2 or depth > 7 or (mode != 0 and mode != 2): return -1
    if player < 1 or player > 2 or count < 0 or count > 20: return -1
    if Int(length) != 4 + Int(count) or player != 1 + count % 2: return -1
    var board = InlineArray[Int, 42](fill=0)
    var heights = InlineArray[Int, 7](fill=0)
    for turn in range(Int(count)):
        let raw = input[4 + turn]
        if raw < 0 or raw >= 7: return -1
        let col = Int(raw)
        let row = heights[col]
        if row == 6: return -1
        let side = 1 + turn % 2
        board[row * 7 + col] = side
        heights[col] = row + 1
        if fm_win(board, col, row, side): return -1
    let side = Int(player)
    var best = -100000 if side == 2 else 100000
    var chosen = 0
    for col in range(7):
        let row = heights[col]
        if row == 6: continue
        board[row * 7 + col] = side
        heights[col] = row + 1
        let value = fm_search(board, heights, 3 - side, 2, Int(depth), Int(mode),
                              best if side == 2 else -100000, 100000 if side == 2 else best)
        heights[col] = row
        board[row * 7 + col] = 0
        if (side == 2 and value > best) or (side == 1 and value <= best):
            best = value
            chosen = col
    return Int64(best * 8 + chosen)
