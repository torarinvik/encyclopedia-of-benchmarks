from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
from std.collections import InlineArray

fn mbg_symbol(x: Int64) -> Bool:
    return (x >= 48 and x <= 57) or (x >= 65 and x <= 90) or (x >= 97 and x <= 122)

@export("matrix_based_game")
fn matrix_based_game(v: UnsafePointer[Int64, ImmutAnyOrigin], n_values: c_size_t) abi("C") -> Int64:
    if v == UnsafePointer[Int64, ImmutAnyOrigin]() or n_values < 2 or n_values > 194: return -1
    if v[0] < 1 or v[0] > 8: return -1
    let d = Int(v[0]); let cells = d*d; let move_idx = 1+cells
    if n_values < c_size_t(move_idx+1) or v[move_idx] < 0 or v[move_idx] > 64: return -1
    let moves = Int(v[move_idx])
    if n_values != c_size_t(2+cells+2*moves): return -1
    var board = InlineArray[Int64,64](fill=0)
    var visited = InlineArray[Bool,64](fill=False)
    var stack = InlineArray[Int,64](fill=0)
    for i in range(cells):
        if not mbg_symbol(v[1+i]): return -1
        board[i] = v[1+i]
    for m in range(moves):
        let x = v[move_idx+1+2*m]; let y = v[move_idx+2+2*m]
        if x < 0 or x >= d or y < 0 or y >= d: return -1
    var score: Int64 = 0
    for move in range(moves):
        let x = Int(v[move_idx+1+2*move]); let y = Int(v[move_idx+2+2*move])
        let start = (d-1-y)*d+x; let color = board[start]
        if color == -1: continue
        for i in range(cells): visited[i] = False
        var stack_count = 1; stack[0] = start; visited[start] = True
        var component: Int64 = 0
        while stack_count > 0:
            stack_count -= 1
            let current = stack[stack_count]; let row = current / d; let col = current % d
            if row > 0:
                let q = current-d
                if not visited[q] and board[q] == color: visited[q] = True; stack[stack_count] = q; stack_count += 1
            if row+1 < d:
                let q = current+d
                if not visited[q] and board[q] == color: visited[q] = True; stack[stack_count] = q; stack_count += 1
            if col > 0:
                let q = current-1
                if not visited[q] and board[q] == color: visited[q] = True; stack[stack_count] = q; stack_count += 1
            if col+1 < d:
                let q = current+1
                if not visited[q] and board[q] == color: visited[q] = True; stack[stack_count] = q; stack_count += 1
            board[current] = -1; component += 1
        score += component*(component+1)/2
        for col in range(d):
            var target_row = d
            for rev in range(d):
                let row = d-1-rev; let value = board[row*d+col]
                if value != -1: target_row -= 1; board[target_row*d+col] = value
            for row in range(target_row): board[row*d+col] = -1
        var write_col = 0
        for col in range(d):
            var nonempty = False
            for row in range(d):
                if board[row*d+col] != -1: nonempty = True
            if not nonempty: continue
            if write_col != col:
                for row in range(d): board[row*d+write_col] = board[row*d+col]
            write_col += 1
        for col in range(write_col,d):
            for row in range(d): board[row*d+col] = -1
    return score
