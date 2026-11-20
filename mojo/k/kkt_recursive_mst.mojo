from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

comptime MAX_N = 16
comptime MAX_M = 16
comptime MAX_INPUT = 52
comptime MASK64 = UInt128(0xFFFFFFFFFFFFFFFF)

struct KktEdge:
    var u: Int
    var v: Int
    var weight: Int64
    var id: Int

fn kkt_edge_less(first: KktEdge, second: KktEdge) -> Bool:
    if first.weight != second.weight: return first.weight < second.weight
    return first.id < second.id

fn kkt_next_splitmix(inout state: UInt64) -> UInt64:
    state = UInt64((UInt128(state) + UInt128(0x9E3779B97F4A7C15)) & MASK64)
    var value = state
    value = UInt64((UInt128(value ^ (value >> 30)) * UInt128(0xBF58476D1CE4E5B9)) & MASK64)
    value = UInt64((UInt128(value ^ (value >> 27)) * UInt128(0x94D049BB133111EB)) & MASK64)
    return value ^ (value >> 31)

fn kkt_root(inout parent: InlineArray[Int, MAX_N], node_input: Int) -> Int:
    var node = node_input
    while parent[node] != node:
        parent[node] = parent[parent[node]]
        node = parent[node]
    return node

fn kkt_sort_edges(inout edges: InlineArray[KktEdge, MAX_M], count: Int):
    for index in range(1, count):
        let key = edges[index]
        var position = index
        while position > 0 and kkt_edge_less(key, edges[position - 1]):
            edges[position] = edges[position - 1]
            position -= 1
        edges[position] = key

fn kkt_boruvka_phase(inout n: Int, inout edges: InlineArray[KktEdge, MAX_M],
                     inout edge_count: Int, inout selected_mask: UInt64):
    if edge_count == 0: return
    var best = InlineArray[Int, MAX_N](fill=-1)
    for vertex in range(n):
        for index in range(edge_count):
            let edge = edges[index]
            if edge.u != vertex and edge.v != vertex: continue
            if best[vertex] < 0 or kkt_edge_less(edge, edges[best[vertex]]):
                best[vertex] = index

    var parent = InlineArray[Int, MAX_N](fill=0)
    for vertex in range(n): parent[vertex] = vertex
    for vertex in range(n):
        if best[vertex] < 0: continue
        let edge = edges[best[vertex]]
        selected_mask = selected_mask | (UInt64(1) << edge.id)
        let first_root = kkt_root(inout parent, edge.u)
        let second_root = kkt_root(inout parent, edge.v)
        if first_root != second_root: parent[first_root] = second_root

    var root_to_local = InlineArray[Int, MAX_N](fill=-1)
    var local_of = InlineArray[Int, MAX_N](fill=0)
    var contracted_n = 0
    for vertex in range(n):
        let representative = kkt_root(inout parent, vertex)
        if root_to_local[representative] < 0:
            root_to_local[representative] = contracted_n
            contracted_n += 1
        local_of[vertex] = root_to_local[representative]

    var contracted = InlineArray[KktEdge, MAX_M](fill=KktEdge(0, 0, 0, 0))
    var contracted_count = 0
    for index in range(edge_count):
        var edge = edges[index]
        var a = local_of[edge.u]
        var b = local_of[edge.v]
        if a == b: continue
        if a > b:
            let temporary = a
            a = b
            b = temporary
        edge.u = a
        edge.v = b
        var duplicate = -1
        for existing in range(contracted_count):
            if contracted[existing].u == a and contracted[existing].v == b:
                duplicate = existing
                break
        if duplicate >= 0:
            if kkt_edge_less(edge, contracted[duplicate]): contracted[duplicate] = edge
        else:
            contracted[contracted_count] = edge
            contracted_count += 1
    n = contracted_n
    edge_count = contracted_count
    edges = contracted

fn kkt_sample_path_max(n: Int, sample: InlineArray[KktEdge, MAX_M], sample_count: Int,
                       forest_mask: UInt64, start: Int, target: Int,
                       inout max_weight: Int64, inout max_id: Int) -> Bool:
    if start < 0 or start >= n or target < 0 or target >= n: return False
    var seen = InlineArray[Bool, MAX_N](fill=False)
    var stack = InlineArray[Int, MAX_N](fill=0)
    var has_max = InlineArray[Bool, MAX_N](fill=False)
    var path_weight = InlineArray[Int64, MAX_N](fill=0)
    var path_id = InlineArray[Int, MAX_N](fill=0)
    var top = 1
    stack[0] = start
    seen[start] = True
    while top > 0 and not seen[target]:
        top -= 1
        let current = stack[top]
        for index in range(sample_count):
            let edge = sample[index]
            if (forest_mask & (UInt64(1) << edge.id)) == 0: continue
            var neighbor = -1
            if edge.u == current: neighbor = edge.v
            elif edge.v == current: neighbor = edge.u
            if neighbor < 0 or seen[neighbor]: continue
            seen[neighbor] = True
            stack[top] = neighbor
            top += 1
            var maximum_weight = edge.weight
            var maximum_id = edge.id
            if has_max[current]:
                maximum_weight = path_weight[current]
                maximum_id = path_id[current]
                if edge.weight > maximum_weight or (edge.weight == maximum_weight and edge.id > maximum_id):
                    maximum_weight = edge.weight
                    maximum_id = edge.id
            has_max[neighbor] = True
            path_weight[neighbor] = maximum_weight
            path_id[neighbor] = maximum_id
    if not seen[target]: return False
    max_weight = path_weight[target]
    max_id = path_id[target]
    return True

fn kkt_recursive(n_input: Int, edge_count_input: Int,
                 input_edges: InlineArray[KktEdge, MAX_M], inout state: UInt64) -> UInt64:
    if edge_count_input == 0: return 0
    var n = n_input
    var edge_count = edge_count_input
    var edges = input_edges
    var selected_mask: UInt64 = 0
    kkt_boruvka_phase(inout n, inout edges, inout edge_count, inout selected_mask)
    if edge_count == 0: return selected_mask
    kkt_boruvka_phase(inout n, inout edges, inout edge_count, inout selected_mask)
    if edge_count == 0: return selected_mask
    kkt_sort_edges(inout edges, edge_count)

    var sample = InlineArray[KktEdge, MAX_M](fill=KktEdge(0, 0, 0, 0))
    var sample_count = 0
    for index in range(edge_count):
        if (kkt_next_splitmix(inout state) & UInt64(1)) != 0:
            sample[sample_count] = edges[index]
            sample_count += 1
    let forest_mask = kkt_recursive(n, sample_count, sample, inout state)

    var light = InlineArray[KktEdge, MAX_M](fill=KktEdge(0, 0, 0, 0))
    var light_count = 0
    for index in range(edge_count):
        let edge = edges[index]
        var maximum_weight: Int64 = 0
        var maximum_id = 0
        let connected = kkt_sample_path_max(n, sample, sample_count, forest_mask,
                                            edge.u, edge.v, inout maximum_weight, inout maximum_id)
        let heavy = connected and (edge.weight > maximum_weight or (edge.weight == maximum_weight and edge.id > maximum_id))
        if not heavy:
            light[light_count] = edge
            light_count += 1
    return selected_mask | kkt_recursive(n, light_count, light, inout state)

@export("kkt_recursive_mst")
fn kkt_recursive_mst(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 3 or length > MAX_INPUT:
        return -1
    let n64 = input[0]
    let m64 = input[1]
    let seed = input[2]
    if n64 < 1 or n64 > MAX_N or m64 < 0 or m64 > MAX_M or seed < 0:
        return -1
    let n = Int(n64)
    let m = Int(m64)
    if length != c_size_t(3 + 3 * m): return -1
    var edges = InlineArray[KktEdge, MAX_M](fill=KktEdge(0, 0, 0, 0))
    for index in range(m):
        let u64 = input[3 + 3 * index]
        let v64 = input[4 + 3 * index]
        let weight = input[5 + 3 * index]
        if u64 < 0 or u64 >= v64 or v64 >= n64 or weight < 0 or weight > 255:
            return -1
        let u = Int(u64)
        let v = Int(v64)
        for previous in range(index):
            if edges[previous].u == u and edges[previous].v == v: return -1
        edges[index] = KktEdge(u, v, weight, index)
    var state = UInt64(seed)
    return Int64(kkt_recursive(n, m, edges, inout state))
