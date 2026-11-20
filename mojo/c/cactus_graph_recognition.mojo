from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

const MAX_N = 32
const MAX_M = 128
const MAX_INPUT = 259
const MAX_ARCS = 256

@export("cactus_graph_recognition")
fn cactus_graph_recognition(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 2 or length > MAX_INPUT: return -1
    let n_value = input[0]
    let m_value = input[1]
    if n_value < 1 or n_value > MAX_N or m_value < 0 or m_value > MAX_M: return -1
    let n = Int(n_value)
    let m = Int(m_value)
    if length != c_size_t(2 + 2 * m): return -1

    var edge_seen = InlineArray[Bool, 1024](fill=False)
    var head = InlineArray[Int, 32](fill=MAX_ARCS)
    var arc_to = InlineArray[Int, 256](fill=0)
    var arc_edge = InlineArray[Int, 256](fill=0)
    var next_arc = InlineArray[Int, 256](fill=0)
    var arc_count = 0
    for e in range(m):
        let u_value = input[2 + 2 * e]
        let v_value = input[3 + 2 * e]
        if u_value < 0 or u_value >= n_value or v_value < 0 or v_value >= n_value or u_value == v_value: return -1
        let u = Int(u_value)
        let v = Int(v_value)
        if edge_seen[u * MAX_N + v]: return -1
        edge_seen[u * MAX_N + v] = True
        edge_seen[v * MAX_N + u] = True
        arc_to[arc_count] = v
        arc_edge[arc_count] = e
        next_arc[arc_count] = head[u]
        head[u] = arc_count
        arc_count += 1
        arc_to[arc_count] = u
        arc_edge[arc_count] = e
        next_arc[arc_count] = head[v]
        head[v] = arc_count
        arc_count += 1

    var state = InlineArray[Int, 32](fill=0)
    var parent = InlineArray[Int, 32](fill=MAX_ARCS)
    var parent_edge = InlineArray[Int, 32](fill=MAX_ARCS)
    var depth = InlineArray[Int, 32](fill=0)
    var cursor = InlineArray[Int, 32](fill=MAX_ARCS)
    var stack = InlineArray[Int, 32](fill=0)
    var cycle_of = InlineArray[Int, 128](fill=MAX_ARCS)
    var used = InlineArray[Bool, 128](fill=False)
    var cycle_vertices = InlineArray[Int, 32](fill=0)
    var cycles = 0
    var edge_cactus = True
    var vertex_cactus = True
    for root in range(n):
        if not edge_cactus: break
        if state[root] != 0: continue
        var top = 1
        state[root] = 1
        cursor[root] = head[root]
        stack[0] = root
        while top > 0 and edge_cactus:
            let current = stack[top - 1]
            let arc = cursor[current]
            if arc == MAX_ARCS:
                state[current] = 2
                top -= 1
                continue
            cursor[current] = next_arc[arc]
            let edge = arc_edge[arc]
            if used[edge]: continue
            used[edge] = True
            let neighbor = arc_to[arc]
            if state[neighbor] == 0:
                parent[neighbor] = current
                parent_edge[neighbor] = edge
                depth[neighbor] = depth[current] + 1
                state[neighbor] = 1
                cursor[neighbor] = head[neighbor]
                stack[top] = neighbor
                top += 1
            elif state[neighbor] == 1 and depth[neighbor] < depth[current]:
                var x = current
                while x != neighbor:
                    let tree_edge = parent_edge[x]
                    if tree_edge == MAX_ARCS or cycle_of[tree_edge] != MAX_ARCS:
                        edge_cactus = False
                        break
                    x = parent[x]
                if not edge_cactus: break
                x = current
                cycle_vertices[x] += 1
                if cycle_vertices[x] > 1: vertex_cactus = False
                while x != neighbor:
                    let tree_edge = parent_edge[x]
                    cycle_of[tree_edge] = cycles
                    x = parent[x]
                    cycle_vertices[x] += 1
                    if cycle_vertices[x] > 1: vertex_cactus = False
                cycle_of[edge] = cycles
                cycles += 1
    if not edge_cactus: return 0
    return Int64(4 * cycles + (if vertex_cactus: 2 else: 0) + 1)
