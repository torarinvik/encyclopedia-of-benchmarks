from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

comptime MAX_N = 8
comptime MAX_M = 20
comptime MAX_INPUT_VALUES = 2 + 3 * MAX_M + 1
comptime INF: Int64 = 1_000_000_000_000

struct Edge:
    var u: Int
    var v: Int
    var weight: Int64

    fn __init__(out self, u: Int, v: Int, weight: Int64):
        self.u = u
        self.v = v
        self.weight = weight

fn shortest_tree(n: Int, m: Int, edges: InlineArray[Edge, MAX_M],
    center_kind: Int, center_root: Int, center_x2: Int64, center_edge: Int,
    mut distance: InlineArray[Int64, MAX_N], mut parent_edge: InlineArray[Int64, MAX_N]):
    var settled = InlineArray[Bool, MAX_N]()
    for vertex in range(n):
        distance[vertex] = INF
        parent_edge[vertex] = -1
    if center_kind == 0:
        distance[center_root] = 0
    else:
        var u = edges[center_edge].u
        var v = edges[center_edge].v
        if u > v:
            let temporary = u
            u = v
            v = temporary
        distance[u] = center_x2
        distance[v] = 2 * edges[center_edge].weight - center_x2
    for _ in range(n):
        var current = n
        for vertex in range(n):
            if not settled[vertex] and (current == n or distance[vertex] < distance[current]):
                current = vertex
        if current == n or distance[current] == INF:
            return
        settled[current] = True
        for edge_id in range(m):
            let left = edges[edge_id].u
            let right = edges[edge_id].v
            if left == right:
                continue
            var neighbor = n
            if current == left:
                neighbor = right
            elif current == right:
                neighbor = left
            else:
                continue
            let candidate = distance[current] + 2 * edges[edge_id].weight
            if not settled[neighbor] and candidate < distance[neighbor]:
                distance[neighbor] = candidate
                parent_edge[neighbor] = Int64(edge_id)

fn selected_tree_diameter(n: Int, edges: InlineArray[Edge, MAX_M],
    selected: InlineArray[Int, MAX_N]) -> Int64:
    var adjacent = InlineArray[Bool, MAX_N * MAX_N]()
    var weight = InlineArray[Int64, MAX_N * MAX_N]()
    for index in range(n - 1):
        let edge = edges[selected[index]]
        adjacent[edge.u * MAX_N + edge.v] = True
        adjacent[edge.v * MAX_N + edge.u] = True
        weight[edge.u * MAX_N + edge.v] = edge.weight
        weight[edge.v * MAX_N + edge.u] = edge.weight
    var diameter: Int64 = 0
    for source in range(n):
        var distance = InlineArray[Int64, MAX_N](fill=Int64(-1))
        var parent = InlineArray[Int, MAX_N](fill=n)
        var stack = InlineArray[Int, MAX_N]()
        var top = 1
        stack[0] = source
        distance[source] = 0
        while top > 0:
            top -= 1
            let current = stack[top]
            diameter = max(diameter, distance[current])
            for neighbor in range(n):
                let cell = current * MAX_N + neighbor
                if adjacent[cell] and parent[current] != neighbor and distance[neighbor] < 0:
                    parent[neighbor] = current
                    distance[neighbor] = distance[current] + weight[cell]
                    stack[top] = neighbor
                    top += 1
    return diameter

fn store_i64_le(output: UnsafePointer[UInt8, MutAnyOrigin], offset: Int, value: Int64):
    let bits = UInt64(value)
    for byte in range(8):
        output[offset + byte] = UInt8((bits >> (8 * byte)) & UInt64(255))

@export("minimum_diameter_spanning_tree")
fn minimum_diameter_spanning_tree(
    input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
    output: UnsafePointer[UInt8, MutAnyOrigin], output_capacity: c_size_t,
) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 2 or length > MAX_INPUT_VALUES:
        return -1
    let n_value = input[0]
    let m_value = input[1]
    if n_value < 1 or n_value > MAX_N or m_value < 0 or m_value > MAX_M:
        return -1
    let n = Int(n_value)
    let m = Int(m_value)
    if length != c_size_t(2 + 3 * m):
        return -1

    var edges = InlineArray[Edge, MAX_M](fill=Edge(0, 0, 0))
    var graph_distance = InlineArray[Int64, MAX_N * MAX_N](fill=INF)
    for u in range(n):
        graph_distance[u * MAX_N + u] = 0
    for edge_id in range(m):
        let offset = 2 + 3 * edge_id
        let u_value = input[offset]
        let v_value = input[offset + 1]
        let edge_weight = input[offset + 2]
        if u_value < 0 or u_value >= n_value or v_value < 0 or v_value >= n_value or (
            edge_weight < 0 or edge_weight > 9
        ):
            return -1
        let u = Int(u_value)
        let v = Int(v_value)
        edges[edge_id] = Edge(u, v, edge_weight)
        if u != v and edge_weight < graph_distance[u * MAX_N + v]:
            graph_distance[u * MAX_N + v] = edge_weight
            graph_distance[v * MAX_N + u] = edge_weight
    for middle in range(n):
        for left in range(n):
            for right in range(n):
                let cell = left * MAX_N + right
                graph_distance[cell] = min(graph_distance[cell],
                    graph_distance[left * MAX_N + middle] + graph_distance[middle * MAX_N + right])
    for vertex in range(n):
        if graph_distance[vertex] == INF:
            return -1

    var best_radius2 = INF
    var best_kind = 0
    var best_root = 0
    var best_edge = 0
    var best_x2: Int64 = 0
    for root in range(n):
        var eccentricity: Int64 = 0
        for vertex in range(n):
            eccentricity = max(eccentricity, graph_distance[root * MAX_N + vertex])
        let radius2 = 2 * eccentricity
        if radius2 < best_radius2:
            best_radius2 = radius2
            best_kind = 0
            best_root = root
    for edge_id in range(m):
        var u = edges[edge_id].u
        var v = edges[edge_id].v
        let edge_weight = edges[edge_id].weight
        if u == v:
            continue
        if u > v:
            let temporary = u
            u = v
            v = temporary
        var x2: Int64 = 0
        while x2 <= 2 * edge_weight:
            var radius2: Int64 = 0
            for vertex in range(n):
                let from_u = 2 * graph_distance[u * MAX_N + vertex] + x2
                let from_v = 2 * graph_distance[v * MAX_N + vertex] + 2 * edge_weight - x2
                radius2 = max(radius2, min(from_u, from_v))
            if radius2 < best_radius2:
                best_radius2 = radius2
                best_kind = 1
                best_root = u
                best_x2 = x2
                best_edge = edge_id
            x2 += 1

    var center_distance = InlineArray[Int64, MAX_N]()
    var parent_edge = InlineArray[Int64, MAX_N]()
    shortest_tree(n, m, edges, best_kind, best_root, best_x2, best_edge,
        mut center_distance, mut parent_edge)
    var selected = InlineArray[Int, MAX_N]()
    var selected_count = 0
    for vertex in range(n):
        if parent_edge[vertex] >= 0:
            selected[selected_count] = Int(parent_edge[vertex])
            selected_count += 1
    if selected_count + 2 == n and best_kind == 1:
        let u = edges[best_edge].u
        let v = edges[best_edge].v
        if parent_edge[u] == -1 and parent_edge[v] == -1:
            selected[selected_count] = best_edge
            selected_count += 1
    if selected_count != n - 1:
        return -1
    for left in range(selected_count):
        for right in range(left + 1, selected_count):
            if selected[right] < selected[left]:
                let temporary = selected[left]
                selected[left] = selected[right]
                selected[right] = temporary

    var staged = InlineArray[Int64, MAX_N]()
    staged[0] = selected_tree_diameter(n, edges, selected)
    for index in range(selected_count):
        staged[index + 1] = Int64(selected[index])
    let required = 8 * n
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or output_capacity < c_size_t(required):
        return -2
    for index in range(n):
        store_i64_le(output, 8 * index, staged[index])
    return Int64(required)
