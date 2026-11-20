from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

alias MAX_VERTICES = 16
alias MAX_INPUT_LENGTH = 246

fn lovasz_toggle_popcount(bits_input: UInt64) -> Int:
    var bits = bits_input
    var count = 0
    while bits != 0:
        bits &= bits - UInt64(1)
        count += 1
    count

@export("lovasz_toggle_defective_coloring_trace")
fn lovasz_toggle_defective_coloring_trace(
    input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 5 or length > MAX_INPUT_LENGTH: return -1
    let n_value = input[0]
    let red_limit_value = input[1]
    let blue_limit_value = input[2]
    let initial_mask_value = input[3]
    let edge_count_value = input[4]
    if n_value < 0 or n_value > MAX_VERTICES: return -1
    if red_limit_value < 1 or red_limit_value > 8 or blue_limit_value < 1 or blue_limit_value > 8: return -1
    let n = Int(n_value)
    if edge_count_value < 0 or edge_count_value > n * (n - 1) // 2: return -1
    let edge_count = Int(edge_count_value)
    if length != c_size_t(5 + 2 * edge_count): return -1
    if initial_mask_value < 0: return -1
    let vertex_mask = (UInt64(1) << n) - UInt64(1)
    let initial_mask = UInt64(initial_mask_value)
    if (initial_mask & ~vertex_mask) != 0: return -1

    var adjacency = InlineArray[UInt64, MAX_VERTICES](fill=UInt64(0))
    for edge in range(edge_count):
        let u_value = input[5 + 2 * edge]
        let v_value = input[6 + 2 * edge]
        if u_value < 0 or v_value <= u_value or v_value >= n_value: return -1
        let u = Int(u_value)
        let v = Int(v_value)
        let u_bit = UInt64(1) << u
        let v_bit = UInt64(1) << v
        if (adjacency[u] & v_bit) != 0: return -1
        adjacency[u] |= v_bit
        adjacency[v] |= u_bit
    let maximum_degree = Int(red_limit_value + blue_limit_value + 1)
    for vertex in range(n):
        if lovasz_toggle_popcount(adjacency[vertex]) > maximum_degree: return -1

    var red_mask = initial_mask
    var toggle_count = Int64(0)
    while True:
        var bad_vertex = n
        for vertex in range(n):
            let bit = UInt64(1) << vertex
            if (red_mask & bit) != 0:
                if lovasz_toggle_popcount(adjacency[vertex] & red_mask) > Int(red_limit_value):
                    bad_vertex = vertex
                    break
            else:
                let blue_mask = vertex_mask & ~red_mask
                if lovasz_toggle_popcount(adjacency[vertex] & blue_mask) > Int(blue_limit_value):
                    bad_vertex = vertex
                    break
        if bad_vertex == n: break
        red_mask ^= UInt64(1) << bad_vertex
        toggle_count += 1
    (toggle_count << n) | Int64(red_mask)
