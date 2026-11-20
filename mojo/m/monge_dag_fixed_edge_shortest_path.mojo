from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

const MAX_N = 32
const SIDE = 33
const MAX_INPUT = 531
const INF: Int64 = 1152921504606846976

@export("monge_dag_fixed_edge_shortest_path")
fn monge_dag_fixed_edge_shortest_path(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 2 or length > MAX_INPUT: return -1
    let n_value = input[0]
    let d_value = input[1]
    if n_value < 1 or n_value > MAX_N or d_value < 1 or d_value > n_value: return -1
    let n = Int(n_value)
    let layers = Int(d_value)
    if length != c_size_t(2 + n * (n + 1) // 2): return -1

    var cost = InlineArray[Int64, 1089](fill=0)
    var offset = 2
    for u in range(n):
        for v in range(u + 1, n + 1):
            let weight = input[offset]
            offset += 1
            if weight < 0 or weight > 1_000_000: return -1
            cost[u * SIDE + v] = weight
    for u in range(max(0, n - 1)):
        for v in range(u + 2, n):
            if cost[u * SIDE + v] + cost[(u + 1) * SIDE + v + 1] > cost[u * SIDE + v + 1] + cost[(u + 1) * SIDE + v]: return -1

    var dp = InlineArray[Int64, 33](fill=INF)
    var next = InlineArray[Int64, 33](fill=INF)
    dp[0] = 0
    for layer in range(1, layers + 1):
        for v in range(n + 1): next[v] = INF
        var rb = InlineArray[Int, 64](fill=0)
        var re = InlineArray[Int, 64](fill=0)
        var cb = InlineArray[Int, 64](fill=0)
        var ce = InlineArray[Int, 64](fill=0)
        var top = 1
        rb[0] = layer
        re[0] = n + 1
        cb[0] = layer - 1
        ce[0] = n
        while top > 0:
            top -= 1
            let row_begin = rb[top]
            let row_end = re[top]
            let col_begin = cb[top]
            let col_end = ce[top]
            if row_begin >= row_end: continue
            let row = (row_begin + row_end) // 2
            let upper = min(col_end, row)
            var best_column = col_begin
            var best_value: Int64 = INF
            for column in range(col_begin, upper):
                if dp[column] == INF: continue
                let candidate = dp[column] + cost[column * SIDE + row]
                if candidate < best_value:
                    best_value = candidate
                    best_column = column
            next[row] = best_value
            if row + 1 < row_end and best_column < col_end:
                rb[top] = row + 1; re[top] = row_end; cb[top] = best_column; ce[top] = col_end; top += 1
            if row_begin < row and col_begin <= best_column:
                rb[top] = row_begin; re[top] = row; cb[top] = col_begin; ce[top] = best_column + 1; top += 1
        dp = next
    return dp[n]
