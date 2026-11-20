from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

fn reachable_count(n: Int, parents: InlineArray[Int, 64], seeds: Int) -> Int64:
    var reached = seeds
    var queue = InlineArray[Int, 8](fill=0)
    var head = 0
    var tail = 0
    for vertex in range(n):
        if (seeds & (1 << vertex)) != 0:
            queue[tail] = vertex
            tail += 1
    while head < tail:
        let source = queue[head]
        head += 1
        for target in range(n):
            let bit = 1 << target
            if parents[target] == source and (reached & bit) == 0:
                reached |= bit
                queue[tail] = target
                tail += 1
    var count: Int64 = 0
    for vertex in range(n):
        if (reached & (1 << vertex)) != 0:
            count += 1
    return count

fn put_i64_le(value: Int64, output: UnsafePointer[UInt8, MutAnyOrigin], offset: Int):
    var bits = bitcast[UInt64](value)
    for byte in range(8):
        output[offset + byte] = UInt8(bits & 255)
        bits >>= 8

@export("influence_maximization_greedy_linear_threshold")
fn influence_maximization_greedy_linear_threshold(
    input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
    output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t
) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 4 or length > 141:
        return -1
    let n0 = input[0]
    let m0 = input[1]
    let k0 = input[2]
    let worlds0 = input[3]
    if (n0 < 1 or n0 > 8 or m0 < 0 or m0 > 24 or k0 < 0 or k0 > n0
            or worlds0 < 1 or worlds0 > 8):
        return -1
    let n = Int(n0)
    let m = Int(m0)
    let k = Int(k0)
    let worlds = Int(worlds0)
    if length != c_size_t(4 + 3 * m + worlds * n):
        return -1

    var edge_u = InlineArray[Int, 24](fill=0)
    var edge_v = InlineArray[Int, 24](fill=0)
    var edge_weight = InlineArray[Int, 24](fill=0)
    var incoming_sum = InlineArray[Int, 8](fill=0)
    for edge in range(m):
        let offset = 4 + 3 * edge
        let u = input[offset]
        let v = input[offset + 1]
        let weight = input[offset + 2]
        if (u < 0 or u >= n0 or v < 0 or v >= n0 or u == v
                or weight < 0 or weight > 256):
            return -1
        for prior in range(edge):
            if edge_u[prior] == Int(u) and edge_v[prior] == Int(v):
                return -1
        edge_u[edge] = Int(u)
        edge_v[edge] = Int(v)
        edge_weight[edge] = Int(weight)
        incoming_sum[Int(v)] += Int(weight)
        if incoming_sum[Int(v)] > 256:
            return -1

    var draws = InlineArray[Int, 64](fill=0)
    let draws_start = 4 + 3 * m
    for world in range(worlds):
        for vertex in range(n):
            let draw = input[draws_start + world * n + vertex]
            if draw < 0 or draw >= 256:
                return -1
            draws[world * 8 + vertex] = Int(draw)

    var parents = InlineArray[Int, 64](fill=-1)
    for world in range(worlds):
        for target in range(n):
            let ticket = draws[world * 8 + target]
            var offset = 0
            for edge in range(m):
                if edge_v[edge] != target:
                    continue
                let next_offset = offset + edge_weight[edge]
                if offset <= ticket and ticket < next_offset:
                    parents[world * 8 + target] = edge_u[edge]
                    break
                offset = next_offset

    var selected = 0
    var chosen = InlineArray[Int64, 8](fill=0)
    var scores = InlineArray[Int64, 8](fill=0)
    for round in range(k):
        var current = InlineArray[Int64, 8](fill=0)
        for world in range(worlds):
            var world_parents = InlineArray[Int, 64](fill=-1)
            for vertex in range(n):
                world_parents[vertex] = parents[world * 8 + vertex]
            current[world] = reachable_count(n, world_parents, selected)
        var best_node = -1
        var best_score: Int64 = -1
        for candidate in range(n):
            let bit = 1 << candidate
            if (selected & bit) != 0:
                continue
            var score: Int64 = 0
            for world in range(worlds):
                var world_parents = InlineArray[Int, 64](fill=-1)
                for vertex in range(n):
                    world_parents[vertex] = parents[world * 8 + vertex]
                score += reachable_count(n, world_parents, selected | bit) - current[world]
            if score > best_score:
                best_node = candidate
                best_score = score
        if best_node < 0:
            return -1
        selected |= 1 << best_node
        chosen[round] = Int64(best_node)
        scores[round] = best_score

    let bytes = 8 * (1 + 2 * k)
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(bytes):
        return -2
    put_i64_le(Int64(k), output, 0)
    for round in range(k):
        put_i64_le(chosen[round], output, 8 * (1 + 2 * round))
        put_i64_le(scores[round], output, 8 * (2 + 2 * round))
    return Int64(bytes)
