from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
from std.collections import InlineArray

const MAX_N = 8
const MAX_INPUT = 17

fn rcc_put64(out: UnsafePointer[UInt8, MutAnyOrigin], offset: Int, value: UInt64):
    for byte in range(8):
        out[offset + byte] = UInt8((value >> UInt64(8 * byte)) & UInt64(255))

fn rcc_path_connectors(source: Int, target: Int, n: Int,
        adjacency: InlineArray[UInt64, MAX_N], order: InlineArray[Int, MAX_N]) -> UInt64:
    var parent = InlineArray[Int, MAX_N](fill=-2)
    var queue = InlineArray[Int, MAX_N](fill=0)
    var head = 0
    var tail = 1
    parent[source] = -1
    queue[0] = source
    while head < tail and parent[target] == -2:
        let current = queue[head]
        head += 1
        for position in range(n):
            let next = order[position]
            if ((adjacency[current] >> UInt64(next)) & UInt64(1)) != 0 and parent[next] == -2:
                parent[next] = current
                queue[tail] = next
                tail += 1
    if parent[target] == -2:
        return UInt64(0)
    var path = InlineArray[Int, MAX_N](fill=0)
    var path_length = 0
    var current = target
    while current != source:
        path[path_length] = current
        path_length += 1
        current = parent[current]
    path[path_length] = source
    path_length += 1
    var connectors = UInt64(0)
    if path_length <= 5:
        for position in range(1, path_length - 1):
            connectors |= UInt64(1) << UInt64(path[position])
    return connectors

@export("routing_cost_constrained_cds_goc_mcds_c")
fn routing_cost_constrained_cds_goc_mcds_c(
        input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
        output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 3 or length > c_size_t(MAX_INPUT):
        return -1
    let raw_n = input[0]
    if raw_n < 1 or raw_n > MAX_N:
        return -1
    let n = Int(raw_n)
    if length != c_size_t(1 + 2 * n):
        return -1
    let full = (UInt64(1) << UInt64(n)) - UInt64(1)
    var adjacency = InlineArray[UInt64, MAX_N](fill=UInt64(0))
    var ids = InlineArray[Int64, MAX_N](fill=Int64(0))
    for vertex in range(n):
        let raw_mask = input[1 + vertex]
        let id = input[1 + n + vertex]
        if raw_mask < 0 or UInt64(raw_mask) > full or
                ((UInt64(raw_mask) >> UInt64(vertex)) & UInt64(1)) != 0 or id < 1 or id > 1000:
            return -1
        adjacency[vertex] = UInt64(raw_mask)
        ids[vertex] = id
        for previous in range(vertex):
            if ids[previous] == id:
                return -1
    for left in range(n):
        for right in range(n):
            let edge_lr = (adjacency[left] >> UInt64(right)) & UInt64(1)
            let edge_rl = (adjacency[right] >> UInt64(left)) & UInt64(1)
            if edge_lr != edge_rl:
                return -1

    var reached = UInt64(1)
    while True:
        var expanded = reached
        for vertex in range(n):
            if ((reached >> UInt64(vertex)) & UInt64(1)) != 0:
                expanded |= adjacency[vertex]
        if expanded == reached:
            break
        reached = expanded
    if reached != full:
        return -1

    var white = full
    var independent = UInt64(0)
    while white != 0:
        var black = UInt64(0)
        for vertex in range(n):
            if ((white >> UInt64(vertex)) & UInt64(1)) == 0:
                continue
            var has_lower_white_neighbor = False
            for other in range(n):
                if ((white >> UInt64(other)) & UInt64(1)) != 0 and
                        ((adjacency[vertex] >> UInt64(other)) & UInt64(1)) != 0 and ids[other] < ids[vertex]:
                    has_lower_white_neighbor = True
            if not has_lower_white_neighbor:
                black |= UInt64(1) << UInt64(vertex)
        if black == 0:
            return -1
        independent |= black
        var removed = black
        for vertex in range(n):
            if ((black >> UInt64(vertex)) & UInt64(1)) != 0:
                removed |= adjacency[vertex]
        white &= ~removed

    var order = InlineArray[Int, MAX_N](fill=0)
    for position in range(n):
        order[position] = position
    for position in range(n):
        var best = position
        for candidate in range(position + 1, n):
            if ids[order[candidate]] < ids[order[best]]:
                best = candidate
        if best != position:
            let temporary = order[position]
            order[position] = order[best]
            order[best] = temporary

    var connectors = UInt64(0)
    for first in range(n):
        let source = order[first]
        if ((independent >> UInt64(source)) & UInt64(1)) == 0:
            continue
        for second in range(first + 1, n):
            let target = order[second]
            if ((independent >> UInt64(target)) & UInt64(1)) != 0:
                connectors |= rcc_path_connectors(source, target, n, adjacency, order)

    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(16):
        return -2
    rcc_put64(output, 0, independent)
    rcc_put64(output, 8, independent | connectors)
    return 16
