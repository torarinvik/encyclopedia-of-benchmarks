from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

fn tlm_owned(graph: InlineArray[Bool, 81], level: InlineArray[Int, 9], n: Int, u: Int,
             inout neighbors: InlineArray[Int, 9]) -> Int:
    var count = 0
    for v in range(n):
        if graph[u * 9 + v] and level[u] == 0 and level[v] == 0:
            neighbors[count] = v
            count += 1
    return count

fn tlm_repair(graph: InlineArray[Bool, 81], level: InlineArray[Int, 9],
              inout mate: InlineArray[Int, 9], n: Int, u: Int):
    if u < 0 or level[u] != 0 or mate[u] >= 0: return
    for v in range(n):
        if graph[u * 9 + v] and level[v] == 0 and mate[v] < 0:
            mate[u] = v
            mate[v] = u
            return

@export("two_level_dynamic_maximal_matching_insertions")
fn two_level_dynamic_maximal_matching_insertions(input: UnsafePointer[Int64, ImmutAnyOrigin],
    length: c_size_t, output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 3 or length > 55: return -1
    let nv = input[0]
    let qv = input[1]
    if (nv != 4 and nv != 9) or qv < 0 or qv > 24 or qv > nv * (nv - 1) // 2: return -1
    if length < c_size_t(3 + 2 * qv): return -1
    let n = Int(nv)
    let q = Int(qv)
    var us = InlineArray[Int, 24](fill=0)
    var vs = InlineArray[Int, 24](fill=0)
    var seen = InlineArray[Bool, 81](fill=False)
    var pos = 2
    for edge in range(q):
        let u = input[pos]
        let v = input[pos + 1]
        pos += 2
        if u < 0 or u >= v or v >= nv: return -1
        let slot = Int(u) * 9 + Int(v)
        if seen[slot]: return -1
        seen[slot] = True
        us[edge] = Int(u)
        vs[edge] = Int(v)
    let rv = input[pos]
    pos += 1
    if rv < 0 or rv > 4 or length != c_size_t(pos + Int(rv)): return -1
    let r = Int(rv)
    var tape = InlineArray[Int, 4](fill=0)
    for i in range(r):
        let rank = input[pos + i]
        if rank < 0 or rank >= nv: return -1
        tape[i] = Int(rank)
    var graph = InlineArray[Bool, 81](fill=False)
    var level = InlineArray[Int, 9](fill=0)
    var mate = InlineArray[Int, 9](fill=-1)
    var consumed = 0
    let threshold = 2 if n == 4 else 3
    for edge in range(q):
        let u = us[edge]
        let v = vs[edge]
        graph[u * 9 + v] = True
        graph[v * 9 + u] = True
        if level[u] == 1 or level[v] == 1: continue
        if mate[u] < 0 and mate[v] < 0:
            mate[u] = v
            mate[v] = u
        var neighbors = InlineArray[Int, 9](fill=0)
        let du = tlm_owned(graph, level, n, u, neighbors)
        let dv = tlm_owned(graph, level, n, v, neighbors)
        let who = u if du > dv or (du == dv and u < v) else v
        let count = tlm_owned(graph, level, n, who, neighbors)
        if count >= threshold:
            if count == 0 or consumed >= r or tape[consumed] >= count: return -1
            let chosen = neighbors[tape[consumed]]
            consumed += 1
            let old_who = mate[who]
            let old_chosen = mate[chosen]
            if old_who >= 0:
                mate[old_who] = -1
                mate[who] = -1
            if old_chosen >= 0:
                mate[old_chosen] = -1
                mate[chosen] = -1
            level[who] = 1
            level[chosen] = 1
            mate[who] = chosen
            mate[chosen] = who
            if old_who >= 0: tlm_repair(graph, level, mate, n, old_who)
            if old_chosen >= 0 and old_chosen != old_who: tlm_repair(graph, level, mate, n, old_chosen)
    if consumed != r: return -1
    let bytes = 8 * (1 + 2 * n)
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(bytes): return -2
    for word in range(1 + 2 * n):
        var value: Int64 = Int64(n)
        if word > 0 and word <= n: value = Int64(level[word - 1])
        elif word > n: value = Int64(mate[word - n - 1])
        let bits = bitcast[UInt64](value)
        for byte in range(8): output[8 * word + byte] = UInt8((bits >> UInt(8 * byte)) & 255)
    return Int64(bytes)
