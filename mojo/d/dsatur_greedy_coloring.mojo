from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

comptime MAX_VERTICES = 12
comptime MAX_EDGES = 66
comptime MAX_INPUT_VALUES = 134
comptime MAX_PARSEABLE_VALUES = 135

fn dsatur_popcount(value_input: UInt64) -> Int:
    var value = value_input
    var count = 0
    while value != 0:
        value = value & (value - UInt64(1))
        count += 1
    return count

@export("dsatur_greedy_coloring")
fn dsatur_greedy_coloring(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 2 or length > MAX_PARSEABLE_VALUES:
        return -1
    let n64 = input[0]
    let m64 = input[1]
    if n64 < 1 or n64 > MAX_VERTICES or m64 < 0 or m64 > MAX_EDGES:
        return -1
    let max_edges = n64 * (n64 - 1) / 2
    if m64 > max_edges:
        return -1
    let n = Int(n64)
    let m = Int(m64)
    if length != c_size_t(2 + 2 * m) or length > MAX_INPUT_VALUES:
        return -1

    var adjacency = InlineArray[UInt64, MAX_VERTICES](fill=0)
    for edge in range(m):
        let u64 = input[2 + 2 * edge]
        let v64 = input[3 + 2 * edge]
        if u64 < 0 or v64 < 0 or u64 >= v64 or v64 >= n64:
            return -1
        let u = Int(u64)
        let v = Int(v64)
        let v_bit = UInt64(1) << v
        if (adjacency[u] & v_bit) != 0:
            return -1
        adjacency[u] = adjacency[u] | v_bit
        adjacency[v] = adjacency[v] | (UInt64(1) << u)

    var colors = InlineArray[Int, MAX_VERTICES](fill=-1)
    var saturation = InlineArray[UInt64, MAX_VERTICES](fill=0)
    var residual_degree = InlineArray[Int, MAX_VERTICES](fill=0)
    for vertex in range(n):
        residual_degree[vertex] = dsatur_popcount(adjacency[vertex])

    var color_count = 0
    for _ in range(n):
        var selected = -1
        var selected_saturation = -1
        var selected_degree = -1
        for vertex in range(n):
            if colors[vertex] >= 0:
                continue
            let sat_count = dsatur_popcount(saturation[vertex])
            let degree = residual_degree[vertex]
            if (selected < 0 or sat_count > selected_saturation
                    or (sat_count == selected_saturation and (degree > selected_degree
                        or (degree == selected_degree and vertex < selected)))):
                selected = vertex
                selected_saturation = sat_count
                selected_degree = degree

        var color = 0
        while (saturation[selected] & (UInt64(1) << color)) != 0:
            color += 1
        colors[selected] = color
        color_count = max(color_count, color + 1)
        let color_bit = UInt64(1) << color
        for neighbor in range(n):
            if colors[neighbor] < 0 and (adjacency[selected] & (UInt64(1) << neighbor)) != 0:
                residual_degree[neighbor] -= 1
                saturation[neighbor] = saturation[neighbor] | color_bit

    var packed = UInt64(color_count) << 48
    for vertex in range(n):
        packed = packed | (UInt64(colors[vertex]) << (4 * vertex))
    return Int64(packed)
