from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

const MAX_VERTICES = 10
const MAX_EDGES = 20
const MAX_COLORS = 8

fn mi_is_forest(input: UnsafePointer[Int64, ImmutAnyOrigin], vertices: Int,
                edges: Int, edge_start: Int, chosen: InlineArray[Bool, 20],
                removed: Int, added: Int) -> Bool:
    var parent = InlineArray[Int64, 10]()
    for vertex in range(vertices): parent[vertex] = Int64(vertex)
    for edge in range(edges):
        if edge != added and (not chosen[edge] or edge == removed): continue
        var a = Int(input[edge_start + 3 * edge])
        var b = Int(input[edge_start + 3 * edge + 1])
        while Int(parent[a]) != a: a = Int(parent[a])
        while Int(parent[b]) != b: b = Int(parent[b])
        if a == b: return False
        parent[b] = Int64(a)
    return True

fn mi_within_quotas(input: UnsafePointer[Int64, ImmutAnyOrigin], colors: Int,
                    edges: Int, edge_start: Int,
                    chosen: InlineArray[Bool, 20], removed: Int,
                    added: Int) -> Bool:
    var counts = InlineArray[Int64, 8]()
    for edge in range(edges):
        if edge != added and (not chosen[edge] or edge == removed): continue
        let color = Int(input[edge_start + 3 * edge + 2])
        counts[color] += 1
        if counts[color] > input[3 + color]: return False
    return True

@export("matroid_intersection")
fn matroid_intersection(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t) -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 4 or length > 72: return -1
    let vertices_value = input[0]
    let edges_value = input[1]
    let colors_value = input[2]
    if vertices_value < 1 or vertices_value > MAX_VERTICES
        or edges_value < 0 or edges_value > MAX_EDGES
        or colors_value < 1 or colors_value > MAX_COLORS: return -1
    let vertices = Int(vertices_value)
    let edges = Int(edges_value)
    let colors = Int(colors_value)
    if Int(length) != 3 + colors + 3 * edges: return -1
    for color in range(colors):
        if input[3 + color] < 0 or input[3 + color] > MAX_EDGES: return -1
    let edge_start = 3 + colors
    for edge in range(edges):
        let u = input[edge_start + 3 * edge]
        let v = input[edge_start + 3 * edge + 1]
        let color = input[edge_start + 3 * edge + 2]
        if u < 0 or u >= vertices_value or v < 0 or v >= vertices_value
            or color < 0 or color >= colors_value: return -1

    var chosen = InlineArray[Bool, 20](fill=False)
    while True:
        var predecessor = InlineArray[Int64, 20](fill=-2)
        var queue = InlineArray[Int64, 20]()
        var head = 0
        var tail = 0
        for edge in range(edges):
            if not chosen[edge] and mi_is_forest(input, vertices, edges, edge_start, chosen, -1, edge):
                predecessor[edge] = -1
                queue[tail] = Int64(edge)
                tail += 1
        var terminal = -1
        while head < tail and terminal < 0:
            let current = Int(queue[head])
            head += 1
            if not chosen[current]:
                if mi_within_quotas(input, colors, edges, edge_start, chosen, -1, current):
                    terminal = current
                    break
                for inside in range(edges):
                    if chosen[inside] and predecessor[inside] == -2
                        and mi_within_quotas(input, colors, edges, edge_start, chosen, inside, current):
                        predecessor[inside] = Int64(current)
                        queue[tail] = Int64(inside)
                        tail += 1
            else:
                for outside in range(edges):
                    if not chosen[outside] and predecessor[outside] == -2
                        and mi_is_forest(input, vertices, edges, edge_start, chosen, current, outside):
                        predecessor[outside] = Int64(current)
                        queue[tail] = Int64(outside)
                        tail += 1
        if terminal < 0: break
        var node = terminal
        while node >= 0:
            chosen[node] = not chosen[node]
            node = Int(predecessor[node])

    var answer: Int64 = 0
    for edge in range(edges):
        if chosen[edge]: answer += 1
    return answer
