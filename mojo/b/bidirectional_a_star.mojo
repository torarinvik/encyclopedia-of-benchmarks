from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
from std.collections import List
from std.math import sqrt

comptime INF = 1_000_000

fn heuristic(a: Int, b: Int, cols: Int) -> Int:
    let dy = a // cols - b // cols; let dx = a % cols - b % cols
    return Int(sqrt(Float64(dy * dy + dx * dx)))

fn append_word(mut bytes: List[UInt8], value: Int64):
    var bits = value
    for _ in range(8): bytes.append(UInt8(bits & 255)); bits >>= 8

@export("bidirectional_a_star")
fn bidirectional_a_star(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
        output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 6: return -1
    let rv = input[0]; let cv = input[1]
    if rv < 1 or rv > 20 or cv < 1 or cv > 20: return -1
    let rows = Int(rv); let cols = Int(cv); let cells = rows * cols
    if input[2] < 0 or input[2] >= rv or input[3] < 0 or input[3] >= cv or input[4] < 0 or input[4] >= rv or input[5] < 0 or input[5] >= cv or length != c_size_t(6 + cells): return -1
    let start = Int(input[2]) * cols + Int(input[3]); let goal = Int(input[4]) * cols + Int(input[5])
    var blocked = List[Bool](capacity=cells)
    for i in range(cells):
        if input[6 + i] != 0 and input[6 + i] != 1: return -1
        blocked.append(input[6 + i] == 1)
    if blocked[start] or blocked[goal]: return -1
    var g = List[Int](capacity=2 * cells); var parent = List[Int](capacity=2 * cells)
    var opened = List[Bool](capacity=2 * cells); var closed = List[Bool](capacity=2 * cells); var order = List[Int](capacity=2 * cells)
    for _ in range(2 * cells): g.append(INF); parent.append(-1); opened.append(False); closed.append(False); order.append(0)
    g[start] = 0; g[cells + goal] = 0; opened[start] = True; opened[cells + goal] = True
    var sequence0 = 1; var sequence1 = 1; var best = INF; var meeting = -1
    while True:
        var min_g0 = INF; var min_g1 = INF
        for v in range(cells):
            if opened[v] and g[v] < min_g0: min_g0 = g[v]
            if opened[cells + v] and g[cells + v] < min_g1: min_g1 = g[cells + v]
        if best < INF and (min_g0 == INF or min_g1 == INF or min_g0 + min_g1 >= best): break
        for side in range(2):
            let base = side * cells
            let other = (1 - side) * cells
            let target = goal if side == 0 else start
            var chosen = -1; var best_f = INF; var best_order = INF
            for v in range(cells):
                let index = base + v
                if not opened[index]: continue
                let f = g[index] + heuristic(v, target, cols)
                if f < best_f or (f == best_f and order[index] < best_order):
                    chosen = v; best_f = f; best_order = order[index]
            if chosen < 0: continue
            let chosen_index = base + chosen
            opened[chosen_index] = False; closed[chosen_index] = True
            if g[other + chosen] < INF and g[chosen_index] + g[other + chosen] < best:
                best = g[chosen_index] + g[other + chosen]; meeting = chosen
            let row = chosen // cols; let col = chosen % cols
            var neighbors = List[Int](capacity=4)
            if row > 0: neighbors.append(chosen - cols)
            if col > 0: neighbors.append(chosen - 1)
            if row + 1 < rows: neighbors.append(chosen + cols)
            if col + 1 < cols: neighbors.append(chosen + 1)
            for v in neighbors:
                let index = base + v
                if blocked[v] or closed[index]: continue
                let candidate = g[chosen_index] + 1
                if candidate < g[index]:
                    g[index] = candidate; parent[index] = chosen; opened[index] = True
                    if side == 0: order[index] = sequence0; sequence0 += 1
                    else: order[index] = sequence1; sequence1 += 1
                    if g[other + v] < INF and candidate + g[other + v] < best:
                        best = candidate + g[other + v]; meeting = v
        var any_open = False
        for i in range(2 * cells):
            if opened[i]: any_open = True
        if not any_open: break
    var path = List[Int](capacity=cells)
    if meeting >= 0:
        var rev = List[Int](capacity=cells); var v = meeting
        while v >= 0: rev.append(v); v = parent[v]
        for j in range(len(rev) - 1, -1, -1): path.append(rev[j])
        v = parent[cells + meeting]
        while v >= 0: path.append(v); v = parent[cells + v]
    else: path.append(start)
    var bytes = List[UInt8](capacity=(1 + 2 * len(path)) * 8)
    append_word(bytes, Int64(len(path)))
    for v in path: append_word(bytes, Int64(v // cols)); append_word(bytes, Int64(v % cols))
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(len(bytes)): return -2
    for i in range(len(bytes)): output[i] = bytes[i]
    return Int64(len(bytes))
