from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

fn crossword_place(words: InlineArray[Int64, 64], lens: InlineArray[Int64, 8], order: InlineArray[Int64, 8], rows: Int64, cols: Int64, depth: Int64, word_count: Int64, inout board: InlineArray[Int64, 64]) -> Bool:
    if depth == word_count: return True
    let w = order[depth]
    let word_len = lens[w]
    for row in range(rows):
        for col in range(cols):
            for direction in range(2):
                let vertical = direction == 0
                if (vertical and row + word_len > rows) or ((not vertical) and col + word_len > cols): continue
                var cells = InlineArray[Int64, 8](0)
                var fresh = InlineArray[Bool, 8](False)
                var valid = True
                for j in range(word_len):
                    let cell = (row + j) * cols + col if vertical else row * cols + col + j
                    cells[j] = cell
                    if board[cell] != 0 and board[cell] != words[w * 8 + j]: valid = False
                if not valid: continue
                for j in range(word_len):
                    let cell = cells[j]
                    fresh[j] = board[cell] == 0
                    board[cell] = words[w * 8 + j]
                if crossword_place(words, lens, order, rows, cols, depth + 1, word_count, board): return True
                for j in range(word_len):
                    if fresh[j]: board[cells[j]] = 0
    return False

@export("crossword_puzzle_solver")
fn crossword_puzzle_solver(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t, output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 3: return -1
    let rows = input[0]
    let cols = input[1]
    let nw = input[2]
    if rows < 1 or rows > 8 or cols < 1 or cols > 8 or nw < 0 or nw > 8 or length < 3 + rows * cols: return -1
    var board = InlineArray[Int64, 64](0)
    var words = InlineArray[Int64, 64](0)
    var lens = InlineArray[Int64, 8](0)
    var order = InlineArray[Int64, 8](0)
    for i in range(rows * cols):
        let c = input[3 + i]
        if c != 0 and c != -1 and (c < 65 or c > 90): return -1
        board[i] = c
    var pos = 3 + rows * cols
    for w in range(nw):
        if pos >= length or input[pos] < 1 or input[pos] > 8: return -1
        lens[w] = input[pos]
        pos += 1
        if lens[w] > length - pos: return -1
        for j in range(lens[w]):
            let c = input[pos]
            if c < 65 or c > 90: return -1
            words[w * 8 + j] = c
            pos += 1
        order[w] = w
    if pos != length: return -1
    for i in range(1, nw):
        let key = order[i]
        var j = i
        while j > 0 and lens[order[j - 1]] < lens[key]:
            order[j] = order[j - 1]
            j -= 1
        order[j] = key
    let solved = crossword_place(words, lens, order, rows, cols, 0, nw, board)
    let bytes = (1 + rows * cols) * 8
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < bytes: return -2
    var stage = InlineArray[Int64, 65](0)
    stage[0] = 1 if solved else 0
    for i in range(rows * cols): stage[i + 1] = board[i]
    for i in range(1 + rows * cols):
        let bits = UInt64(stage[i])
        for b in range(8): output[i * 8 + b] = UInt8((bits >> (8 * b)) & 255)
    return bytes
