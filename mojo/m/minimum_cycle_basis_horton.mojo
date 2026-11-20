from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

comptime MCB_MAX_N = 8
comptime MCB_MAX_M = 12
comptime MCB_MAX_LENGTH = 39
comptime MCB_MAX_CANDIDATES = 96
comptime MCB_INF = Int64(0x3fffffffffffffff)

@fieldwise_init
struct McbEdge(Copyable):
    var u: Int
    var v: Int
    var weight: Int64

fn mcb_cycle_weight(mask: UInt64, edges: InlineArray[McbEdge, MCB_MAX_M], m: Int) -> Int64:
    var total = Int64(0)
    for e in range(m):
        if ((mask >> e) & 1) != 0:
            total += edges[e].weight
    return total

fn mcb_horton_weight(n: Int, m: Int, edges: InlineArray[McbEdge, MCB_MAX_M]) -> Int64:
    var candidates = InlineArray[UInt64, MCB_MAX_CANDIDATES](fill=UInt64(0))
    var costs = InlineArray[Int64, MCB_MAX_CANDIDATES](fill=Int64(0))
    var candidate_count = 0
    for root in range(n):
        var distance = InlineArray[Int64, MCB_MAX_N](fill=MCB_INF)
        var parent = InlineArray[Int, MCB_MAX_N](fill=-1)
        var parent_edge = InlineArray[Int, MCB_MAX_N](fill=-1)
        var settled = InlineArray[Bool, MCB_MAX_N](fill=False)
        var tree_edge = InlineArray[Bool, MCB_MAX_M](fill=False)
        var path_mask = InlineArray[UInt64, MCB_MAX_N](fill=UInt64(0))
        distance[root] = 0
        let tie_scale = Int64(m + 1) * (Int64(1) << m)
        for _ in range(n):
            var vertex = -1
            for v in range(n):
                if not settled[v] and distance[v] != MCB_INF and (vertex < 0 or distance[v] < distance[vertex] or (distance[v] == distance[vertex] and v < vertex)):
                    vertex = v
            if vertex < 0:
                break
            settled[vertex] = True
            for e in range(m):
                let edge = edges[e]
                var neighbor = -1
                if edge.u == vertex:
                    neighbor = edge.v
                elif edge.v == vertex:
                    neighbor = edge.u
                if neighbor < 0 or settled[neighbor]:
                    continue
                let candidate = distance[vertex] + edge.weight * tie_scale + (Int64(1) << e)
                if candidate < distance[neighbor]:
                    distance[neighbor] = candidate
                    parent[neighbor] = vertex
                    parent_edge[neighbor] = e
        for v in range(n):
            if v == root:
                continue
            var cursor = v
            var steps = 0
            while cursor != root and steps < n:
                let pe = parent_edge[cursor]
                if pe < 0:
                    return -1
                tree_edge[pe] = True
                path_mask[v] = path_mask[v] | (UInt64(1) << pe)
                cursor = parent[cursor]
                steps += 1
            if cursor != root:
                return -1
        for e in range(m):
            if tree_edge[e]:
                continue
            let edge = edges[e]
            let cycle = path_mask[edge.u] ^ path_mask[edge.v] ^ (UInt64(1) << e)
            if cycle == 0:
                continue
            var duplicate = False
            for i in range(candidate_count):
                if candidates[i] == cycle:
                    duplicate = True
                    break
            if not duplicate and candidate_count < MCB_MAX_CANDIDATES:
                candidates[candidate_count] = cycle
                costs[candidate_count] = mcb_cycle_weight(cycle, edges, m)
                candidate_count += 1
    for i in range(candidate_count):
        for j in range(i + 1, candidate_count):
            if costs[j] < costs[i] or (costs[j] == costs[i] and candidates[j] < candidates[i]):
                let old_cost = costs[i]
                costs[i] = costs[j]
                costs[j] = old_cost
                let old_mask = candidates[i]
                candidates[i] = candidates[j]
                candidates[j] = old_mask
    let dimension = m - n + 1
    var basis = InlineArray[UInt64, MCB_MAX_M](fill=UInt64(0))
    var rank = 0
    var total = Int64(0)
    for i in range(candidate_count):
        if rank == dimension:
            break
        var residual = candidates[i]
        for bit in range(m - 1, -1, -1):
            if ((residual >> bit) & 1) == 0:
                continue
            if basis[bit] != 0:
                residual = residual ^ basis[bit]
            else:
                basis[bit] = residual
                rank += 1
                total += costs[i]
                break
    if rank == dimension:
        return total
    return -1

fn mcb_impl(input: UnsafePointer[Int64, ImmutAnyOrigin], length: Int) -> Int64:
    if length < 2 or length > MCB_MAX_LENGTH:
        return -1
    if input[0] < 3 or input[0] > MCB_MAX_N:
        return -1
    let n = Int(input[0])
    let n_i64 = Int64(n)
    if input[1] < n_i64 - 1 or input[1] > MCB_MAX_M or input[1] > Int64(n * (n - 1) // 2):
        return -1
    let m = Int(input[1])
    if length != 2 + 3 * m:
        return -1
    var edges = InlineArray[McbEdge, MCB_MAX_M](fill=McbEdge(0, 0, 0))
    var adjacent = InlineArray[Bool, MCB_MAX_N * MCB_MAX_N](fill=False)
    var previous_u = -1
    var previous_v = -1
    for e in range(m):
        let ru = input[2 + 3 * e]
        let rv = input[3 + 3 * e]
        let weight = input[4 + 3 * e]
        if ru < 0 or rv < 0 or ru >= n_i64 or rv >= n_i64 or ru >= rv or weight < 1 or weight > 9:
            return -1
        let u = Int(ru)
        let v = Int(rv)
        if e > 0 and (u < previous_u or (u == previous_u and v <= previous_v)):
            return -1
        previous_u = u
        previous_v = v
        edges[e] = McbEdge(u, v, weight)
        adjacent[u * MCB_MAX_N + v] = True
        adjacent[v * MCB_MAX_N + u] = True
    var seen = InlineArray[Bool, MCB_MAX_N](fill=False)
    var queue = InlineArray[Int, MCB_MAX_N](fill=0)
    var head = 0
    var tail = 1
    seen[0] = True
    while head < tail:
        let u = queue[head]
        head += 1
        for v in range(n):
            if adjacent[u * MCB_MAX_N + v] and not seen[v]:
                seen[v] = True
                queue[tail] = v
                tail += 1
    for v in range(n):
        if not seen[v]:
            return -1
    return mcb_horton_weight(n, m, edges)

@export("minimum_cycle_basis_horton")
fn minimum_cycle_basis_horton(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length > c_size_t(MCB_MAX_LENGTH):
        return -1
    return mcb_impl(input, Int(length))
