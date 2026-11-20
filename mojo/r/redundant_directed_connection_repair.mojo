from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

comptime MAX_N = 16

fn repair_find(mut parent: InlineArray[Int, MAX_N], node_input: Int) -> Int:
    var node = node_input
    while parent[node] != node:
        parent[node] = parent[parent[node]]
        node = parent[node]
    return node

@export("redundant_directed_connection_repair")
fn redundant_directed_connection_repair(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t) -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 1 or length > 34: return -1
    let n_value = input[0]
    if n_value < 3 or n_value > MAX_N: return -1
    let n = Int(n_value)
    if Int(length) != 1 + 2 * n: return -1
    var from = InlineArray[Int, MAX_N](fill=0)
    var to = InlineArray[Int, MAX_N](fill=0)
    var incoming = InlineArray[Int, MAX_N](fill=-1)
    var parent = InlineArray[Int, MAX_N](fill=0)
    var sizes = InlineArray[Int, MAX_N](fill=1)
    for node in range(n): parent[node] = node
    for edge in range(n):
        let u = input[1 + 2 * edge]
        let v = input[2 + 2 * edge]
        if u < 0 or u >= n_value or v < 0 or v >= n_value or u == v: return -1
        from[edge] = Int(u)
        to[edge] = Int(v)
        for prior in range(edge):
            if from[prior] == from[edge] and to[prior] == to[edge]: return -1
    var first_parent = -1
    var second_parent = -1
    for edge in range(n):
        let child = to[edge]
        if incoming[child] < 0:
            incoming[child] = edge
        else:
            first_parent = incoming[child]
            second_parent = edge
            break
    var cycle_edge = -1
    for edge in range(n):
        if edge == second_parent: continue
        var a = repair_find(mut parent, from[edge])
        var b = repair_find(mut parent, to[edge])
        if a == b:
            cycle_edge = edge
            break
        if sizes[a] < sizes[b]:
            let swap = a
            a = b
            b = swap
        parent[b] = a
        sizes[a] += sizes[b]
    if cycle_edge >= 0:
        if second_parent >= 0: return first_parent
        return cycle_edge
    return second_parent
