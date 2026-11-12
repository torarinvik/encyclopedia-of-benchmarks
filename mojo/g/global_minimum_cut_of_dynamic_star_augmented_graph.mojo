from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

comptime GMC_MAX_N = 16
comptime GMC_MAX_M = 64
comptime GMC_MAX_Q = 32
comptime GMC_MAX_V = 17
comptime GMC_MAX_INPUT = 276
comptime GMC_MAX_OUTPUT = 256
comptime GMC_MAX_W: Int64 = 1000000

fn gmc_stoer_wagner(n: Int, spokes: InlineArray[Int64, 16], m: Int,
    edge_u: InlineArray[Int32, 64], edge_v: InlineArray[Int32, 64],
    edge_w: InlineArray[Int64, 64]) -> Int64:
    let vertex_count = n + 1
    var weights = InlineArray[InlineArray[Int64, 17], 17]()
    for e in range(m):
        let u = Int(edge_u[e]); let v = Int(edge_v[e])
        weights[u][v] += edge_w[e]; weights[v][u] += edge_w[e]
    for u in range(n):
        weights[u][n] += spokes[u]; weights[n][u] += spokes[u]
    var active = InlineArray[Int32, 17]()
    for i in range(vertex_count): active[i] = Int32(i)
    var count = vertex_count
    var best: Int64 = 9223372036854775807
    while count > 1:
        var used = InlineArray[Bool, 17]()
        var connection = InlineArray[Int64, 17]()
        var previous = -1
        for step in range(count):
            var selected = -1
            for z in range(count):
                let u = Int(active[z])
                if not used[u] and (selected < 0 or connection[u] > connection[selected]
                        or (connection[u] == connection[selected] and u < selected)):
                    selected = u
            if step + 1 == count:
                best = min(best, connection[selected])
                for z in range(count):
                    let u = Int(active[z])
                    if u != selected and u != previous:
                        weights[previous][u] += weights[selected][u]
                        weights[u][previous] = weights[previous][u]
                var pos = 0
                while Int(active[pos]) != selected: pos += 1
                for z in range(pos + 1, count): active[z - 1] = active[z]
                count -= 1
                break
            used[selected] = True
            previous = selected
            for z in range(count):
                let u = Int(active[z])
                if not used[u]: connection[u] += weights[selected][u]
    return best

@export("global_minimum_cut_of_dynamic_star_augmented_graph")
fn global_minimum_cut_of_dynamic_star_augmented_graph(
    input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
    output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t,
) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 3 or length > GMC_MAX_INPUT: return -1
    let count = Int(length); let n0 = input[0]; let m0 = input[1]; let q0 = input[2]
    if n0 < 1 or n0 > GMC_MAX_N or m0 < 0 or m0 > GMC_MAX_M
            or m0 > n0 * (n0 - 1) / 2 or q0 < 1 or q0 > GMC_MAX_Q: return -1
    let n = Int(n0); let m = Int(m0); let q = Int(q0)
    if count != 3 + n + 3 * m + 2 * q: return -1
    var pos = 3
    var spokes = InlineArray[Int64, 16]()
    for i in range(n):
        spokes[i] = input[pos]; pos += 1
        if spokes[i] < 0 or spokes[i] > GMC_MAX_W: return -1
    var edge_u = InlineArray[Int32, 64](); var edge_v = InlineArray[Int32, 64](); var edge_w = InlineArray[Int64, 64]()
    var seen = InlineArray[Bool, 256]()
    for e in range(m):
        let u0 = input[pos]; let v0 = input[pos + 1]; let weight = input[pos + 2]; pos += 3
        if u0 < 0 or u0 >= n0 or v0 < 0 or v0 >= n0 or u0 == v0 or weight < 0 or weight > GMC_MAX_W: return -1
        let u = Int(u0); let v = Int(v0); let a = min(u, v); let b = max(u, v); let slot = a * 16 + b
        if seen[slot]: return -1
        seen[slot] = True; edge_u[e] = Int32(u); edge_v[e] = Int32(v); edge_w[e] = weight
    var update_x = InlineArray[Int32, 32](); var update_y = InlineArray[Int64, 32]()
    for i in range(q):
        let x = input[pos]; let y = input[pos + 1]; pos += 2
        if x < 0 or x >= n0 or y < 0 or y > GMC_MAX_W: return -1
        update_x[i] = Int32(x); update_y[i] = y
    let bytes = 8 * q
    if bytes > GMC_MAX_OUTPUT: return -1
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or Int(capacity) < bytes: return -2
    var answers = InlineArray[Int64, 32]()
    for i in range(q):
        spokes[Int(update_x[i])] = update_y[i]
        answers[i] = gmc_stoer_wagner(n, spokes, m, edge_u, edge_v, edge_w)
    for i in range(q):
        let bits = bitcast[UInt64](answers[i])
        for byte in range(8): output[i * 8 + byte] = UInt8((bits >> UInt(byte * 8)) & 255)
    return Int64(bytes)
