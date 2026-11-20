from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

const N = 8
const M = 16
const F = 10
const INPUT_MAX = 79
const NODE_MAX = 20
const EDGE_MAX = 200
const INF: Int64 = 1 << 60

struct BendFlowEdge(Copyable):
    var from_node: Int
    var to_node: Int
    var reverse_index: Int
    var capacity: Int64
    var cost: Int64

fn bend_connected(adjacency: InlineArray[Bool, 64], n: Int, removed: Int) -> Bool:
    let start = 1 if removed == 0 else 0
    var seen = InlineArray[Bool, 8](fill=False)
    var stack = InlineArray[Int, 8](fill=0)
    var top = 1
    var count = 0
    seen[start] = True
    stack[0] = start
    while top > 0:
        top -= 1
        let u = stack[top]
        count += 1
        for v in range(n):
            if v != removed and adjacency[u * 8 + v] and not seen[v]:
                seen[v] = True
                stack[top] = v
                top += 1
    let expected = n - (1 if removed >= 0 else 0)
    return count == expected

fn bend_add_arc(mut edges: InlineArray[BendFlowEdge, 200], mut edge_count: Int,
                u: Int, v: Int, capacity: Int64, cost: Int64) -> Bool:
    if edge_count + 2 > EDGE_MAX: return False
    let e = edge_count
    edges[e] = BendFlowEdge(u, v, e + 1, capacity, cost)
    edges[e + 1] = BendFlowEdge(v, u, e, 0, -cost)
    edge_count += 2
    return True

@export("orthogonal_drawing_minimum_bends")
fn orthogonal_drawing_minimum_bends(
    input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
    output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t,
) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 4 or length > INPUT_MAX: return -1
    let n0 = input[0]
    let m0 = input[1]
    let f0 = input[2]
    let outer0 = input[3]
    if n0 < 3 or n0 > 8 or m0 < n0 or m0 > 16 or f0 < 2 or f0 > 10 or
        f0 != m0 - n0 + 2 or outer0 < 0 or outer0 >= f0: return -1
    let n = Int(n0)
    let m = Int(m0)
    let f = Int(f0)
    let outer = Int(outer0)
    var adjacency = InlineArray[Bool, 64](fill=False)
    var degree = InlineArray[Int, 8](fill=0)
    var edge_u = InlineArray[Int, 16](fill=0)
    var edge_v = InlineArray[Int, 16](fill=0)
    var uses = InlineArray[Int, 64](fill=0)
    var cursor = 4
    for e in range(m):
        if cursor + 2 > Int(length): return -1
        let u0 = input[cursor]
        let v0 = input[cursor + 1]
        cursor += 2
        if u0 < 0 or u0 >= v0 or v0 >= n0: return -1
        let u = Int(u0)
        let v = Int(v0)
        if adjacency[u * 8 + v] or (e > 0 and (u < edge_u[e - 1] or (u == edge_u[e - 1] and v <= edge_v[e - 1]))): return -1
        adjacency[u * 8 + v] = True
        adjacency[v * 8 + u] = True
        degree[u] += 1
        degree[v] += 1
        edge_u[e] = u
        edge_v[e] = v
    for v in range(n):
        if degree[v] < 2 or degree[v] > 4: return -1

    var faces = InlineArray[Int, 80](fill=0)
    var widths = InlineArray[Int, 10](fill=0)
    var link_adj = InlineArray[Bool, 512](fill=False)
    var link_degree = InlineArray[Int, 64](fill=0)
    for face in range(f):
        if cursor >= Int(length): return -1
        let width0 = input[cursor]
        cursor += 1
        if width0 < 3 or width0 > n0 or cursor + Int(width0) > Int(length): return -1
        let width = Int(width0)
        widths[face] = width
        var row_seen = InlineArray[Bool, 8](fill=False)
        for i in range(width):
            let vertex0 = input[cursor]
            cursor += 1
            if vertex0 < 0 or vertex0 >= n0: return -1
            let vertex = Int(vertex0)
            if row_seen[vertex]: return -1
            row_seen[vertex] = True
            faces[face * 8 + i] = vertex
        for i in range(width):
            let u = faces[face * 8 + i]
            let v = faces[face * 8 + (i + 1) % width]
            if not adjacency[u * 8 + v]: return -1
            uses[u * 8 + v] += 1
        for i in range(width):
            let center = faces[face * 8 + i]
            let before = faces[face * 8 + (i + width - 1) % width]
            let after = faces[face * 8 + (i + 1) % width]
            if before == after: return -1
            link_adj[(center * 8 + before) * 8 + after] = True
            link_adj[(center * 8 + after) * 8 + before] = True
            link_degree[center * 8 + before] += 1
            link_degree[center * 8 + after] += 1
    if cursor != Int(length) or n - m + f != 2 or not bend_connected(adjacency, n, -1): return -1
    for v in range(n):
        if not bend_connected(adjacency, n, v): return -1
    for e in range(m):
        if uses[edge_u[e] * 8 + edge_v[e]] != 1 or uses[edge_v[e] * 8 + edge_u[e]] != 1: return -1
    for center in range(n):
        var start = -1
        var incident_count = 0
        for neighbor in range(n):
            if adjacency[center * 8 + neighbor]:
                if link_degree[center * 8 + neighbor] != 2: return -1
                if start < 0: start = neighbor
                incident_count += 1
            elif link_degree[center * 8 + neighbor] != 0: return -1
        var seen = InlineArray[Bool, 8](fill=False)
        var stack = InlineArray[Int, 8](fill=0)
        var top = 1
        var reached = 0
        seen[start] = True
        stack[0] = start
        while top > 0:
            top -= 1
            let neighbor = stack[top]
            reached += 1
            for other in range(n):
                if link_adj[(center * 8 + neighbor) * 8 + other] and not seen[other]:
                    seen[other] = True
                    stack[top] = other
                    top += 1
        if reached != incident_count: return -1
    var face_a = InlineArray[Int, 16](fill=0)
    var face_b = InlineArray[Int, 16](fill=0)
    var face_use = InlineArray[Int, 16](fill=0)
    for face in range(f):
        for i in range(widths[face]):
            let u = faces[face * 8 + i]
            let v = faces[face * 8 + (i + 1) % widths[face]]
            let lo = u if u < v else v
            let hi = v if u < v else u
            var found = -1
            for e in range(m):
                if edge_u[e] == lo and edge_v[e] == hi:
                    found = e
                    break
            if found < 0 or face_use[found] >= 2: return -1
            if face_use[found] == 0: face_a[found] = face
            else: face_b[found] = face
            face_use[found] += 1
    for e in range(m):
        if face_use[e] != 2 or face_a[e] == face_b[e]: return -1
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < 8: return -2

    let base = n + f
    let source = base
    let sink = base + 1
    let node_count = base + 2
    var edges = InlineArray[BendFlowEdge, EDGE_MAX](fill=BendFlowEdge(0, 0, 0, 0, 0))
    var edge_count = 0
    var balance = InlineArray[Int64, 18](fill=0)
    for v in range(n): balance[v] = 4
    for face in range(f):
        let d = Int64(widths[face])
        let offset = 4 if face == outer else -4
        balance[n + face] -= 2 * d + offset
        for i in range(widths[face]):
            let v = faces[face * 8 + i]
            balance[v] -= 1
            balance[n + face] += 1
            if not bend_add_arc(edges, edge_count, v, n + face, Int64(4 * n), 0): return -1
    for e in range(m):
        if not bend_add_arc(edges, edge_count, n + face_a[e], n + face_b[e], Int64(4 * n), 1): return -1
        if not bend_add_arc(edges, edge_count, n + face_b[e], n + face_a[e], Int64(4 * n), 1): return -1
    var required: Int64 = 0
    for v in range(base):
        if balance[v] > 0:
            if not bend_add_arc(edges, edge_count, source, v, balance[v], 0): return -1
            required += balance[v]
        elif balance[v] < 0:
            if not bend_add_arc(edges, edge_count, v, sink, -balance[v], 0): return -1
    var potential = InlineArray[Int64, NODE_MAX](fill=0)
    var total_flow: Int64 = 0
    var total_cost: Int64 = 0
    while total_flow < required:
        var dist = InlineArray[Int64, NODE_MAX](fill=INF)
        var parent = InlineArray[Int, NODE_MAX](fill=-1)
        var used = InlineArray[Bool, NODE_MAX](fill=False)
        dist[source] = 0
        for _ in range(node_count):
            var chosen = -1
            for v in range(node_count):
                if not used[v] and dist[v] != INF and (chosen < 0 or dist[v] < dist[chosen]): chosen = v
            if chosen < 0: break
            used[chosen] = True
            for e in range(edge_count):
                if edges[e].from_node != chosen or edges[e].capacity <= 0: continue
                let v = edges[e].to_node
                let candidate = dist[chosen] + edges[e].cost + potential[chosen] - potential[v]
                if not used[v] and candidate < dist[v]:
                    dist[v] = candidate
                    parent[v] = e
        if dist[sink] == INF: return -1
        for v in range(node_count):
            if dist[v] != INF: potential[v] += dist[v]
        var amount = required - total_flow
        var path_cost: Int64 = 0
        var vertex = sink
        while vertex != source:
            let e = parent[vertex]
            if e < 0: return -1
            amount = min(amount, edges[e].capacity)
            path_cost += edges[e].cost
            vertex = edges[e].from_node
        vertex = sink
        while vertex != source:
            let e = parent[vertex]
            let previous = edges[e].from_node
            edges[e].capacity -= amount
            edges[edges[e].reverse_index].capacity += amount
            vertex = previous
        total_flow += amount
        total_cost += amount * path_cost
    let bits = UInt64(total_cost)
    for i in range(8): output[i] = UInt8((bits >> (8 * i)) & 255)
    return 8
