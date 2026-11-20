from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
from std.collections import InlineArray

alias MAX_N = 16
alias MAX_EDGES = 15
alias MAX_ARCS = 30
alias MAX_INPUT_LENGTH = 48

fn tree_random_walk_edge_hitting_cost_store(
    output: UnsafePointer[UInt8, MutAnyOrigin], offset: Int, value: Int64
):
    let bits = value.bitcast[UInt64]()
    for byte in range(8):
        output[offset + byte] = UInt8((bits >> (8 * byte)) & 255)

@export("tree_random_walk_edge_hitting_cost")
fn tree_random_walk_edge_hitting_cost(
    input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
    output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t
) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 2 or length > MAX_INPUT_LENGTH:
        return -1
    let n_value = input[0]
    let root_value = input[1]
    if n_value < 1 or n_value > MAX_N or root_value < 0 or root_value >= n_value:
        return -1
    let n = Int(n_value)
    let root = Int(root_value)
    let edge_count = n - 1
    if length != c_size_t(2 + 3 * edge_count): return -1

    var head = InlineArray[Int32, MAX_N]()
    var to = InlineArray[Int32, MAX_ARCS]()
    var next_arc = InlineArray[Int32, MAX_ARCS]()
    var sets = InlineArray[Int32, MAX_N]()
    var input_u = InlineArray[Int32, MAX_EDGES]()
    var input_v = InlineArray[Int32, MAX_EDGES]()
    var incident_sum = InlineArray[Int64, MAX_N]()
    var down = InlineArray[Int64, MAX_N]()
    var up = InlineArray[Int64, MAX_N]()
    for vertex in range(n):
        head[vertex] = -1
        sets[vertex] = Int32(vertex)
    var arc_count = 0
    for edge in range(edge_count):
        let offset = 2 + 3 * edge
        let u_value = input[offset]
        let v_value = input[offset + 1]
        let weight = input[offset + 2]
        if u_value < 0 or u_value >= n_value or v_value < 0 or v_value >= n_value
                or u_value == v_value or weight < 1 or weight > 9:
            return -1
        let u = Int(u_value)
        let v = Int(v_value)
        var set_u = u
        while sets[set_u] != Int32(set_u):
            sets[set_u] = sets[Int(sets[set_u])]
            set_u = Int(sets[set_u])
        var set_v = v
        while sets[set_v] != Int32(set_v):
            sets[set_v] = sets[Int(sets[set_v])]
            set_v = Int(sets[set_v])
        if set_u == set_v: return -1
        sets[set_v] = Int32(set_u)
        input_u[edge] = Int32(u)
        input_v[edge] = Int32(v)
        to[arc_count] = Int32(v)
        next_arc[arc_count] = head[u]
        head[u] = Int32(arc_count)
        arc_count += 1
        to[arc_count] = Int32(u)
        next_arc[arc_count] = head[v]
        head[v] = Int32(arc_count)
        arc_count += 1
        incident_sum[u] += weight
        incident_sum[v] += weight

    let output_bytes = 16 * edge_count
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(output_bytes):
        return -2

    var parent = InlineArray[Int32, MAX_N]()
    var order = InlineArray[Int32, MAX_N]()
    for vertex in range(n): parent[vertex] = -1
    parent[root] = Int32(root)
    order[0] = Int32(root)
    var order_size = 1
    var cursor = 0
    while cursor < order_size:
        let vertex = Int(order[cursor])
        var arc = head[vertex]
        while arc >= 0:
            let index = Int(arc)
            let neighbor = Int(to[index])
            if parent[neighbor] == -1:
                parent[neighbor] = Int32(vertex)
                order[order_size] = Int32(neighbor)
                order_size += 1
            arc = next_arc[index]
        cursor += 1

    for position in range(n):
        let vertex = Int(order[n - 1 - position])
        down[vertex] = incident_sum[vertex]
        var arc = head[vertex]
        while arc >= 0:
            let index = Int(arc)
            let child = Int(to[index])
            if parent[child] == Int32(vertex): down[vertex] += down[child]
            arc = next_arc[index]
    for position in range(n):
        let vertex = Int(order[position])
        var arc = head[vertex]
        while arc >= 0:
            let index = Int(arc)
            let child = Int(to[index])
            if parent[child] == Int32(vertex):
                up[child] = up[vertex] + down[vertex] - down[child]
            arc = next_arc[index]

    for edge in range(edge_count):
        let u = Int(input_u[edge])
        let v = Int(input_v[edge])
        var toward_v: Int64 = 0
        var toward_u: Int64 = 0
        if parent[u] == Int32(v):
            toward_v = down[u]
            toward_u = up[u]
        else:
            toward_v = up[v]
            toward_u = down[v]
        tree_random_walk_edge_hitting_cost_store(output, 16 * edge, toward_v)
        tree_random_walk_edge_hitting_cost_store(output, 16 * edge + 8, toward_u)
    Int64(output_bytes)
