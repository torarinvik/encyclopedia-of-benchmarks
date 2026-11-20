from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

comptime MAX_N = 64
comptime MAX_INPUT = 65

fn lc_solve(n: Int, parent: InlineArray[Int, MAX_N],
            inout first_child: InlineArray[Int, MAX_N],
            inout next_sibling: InlineArray[Int, MAX_N],
            inout height: InlineArray[Int, MAX_N],
            inout heavy: InlineArray[Int, MAX_N],
            inout base: InlineArray[Int, MAX_N],
            inout count: InlineArray[Int, MAX_N],
            inout dominant_depth: InlineArray[Int, MAX_N]):
    for vertex in range(n):
        first_child[vertex] = -1
        heavy[vertex] = -1
        height[vertex] = 1
    for vertex in range(1, n):
        let p = parent[vertex]
        next_sibling[vertex] = first_child[p]
        first_child[p] = vertex

    for reverse in range(n):
        let vertex = n - 1 - reverse
        var child = first_child[vertex]
        var maximum_height = 0
        while child >= 0:
            let child_height = height[child]
            if child_height > maximum_height or (child_height == maximum_height and child < heavy[vertex]):
                maximum_height = child_height
                heavy[vertex] = child
            child = next_sibling[child]
        height[vertex] = maximum_height + 1

    var pool_size = 0
    for vertex in range(n):
        if vertex == 0 or heavy[parent[vertex]] != vertex:
            var current = vertex
            while current >= 0:
                base[current] = pool_size
                pool_size += 1
                current = heavy[current]

    for reverse in range(n):
        let vertex = n - 1 - reverse
        count[base[vertex]] = 1
        var best_depth = 0
        var best_count = 1
        let heavy_child = heavy[vertex]
        if heavy_child >= 0:
            best_depth = dominant_depth[heavy_child] + 1
            best_count = count[base[vertex] + best_depth]
        var child = first_child[vertex]
        while child >= 0:
            if child != heavy_child:
                for child_depth in range(height[child]):
                    let depth = child_depth + 1
                    let slot = base[vertex] + depth
                    let amount = count[slot] + count[base[child] + child_depth]
                    count[slot] = amount
                    if amount > best_count or (amount == best_count and depth < best_depth):
                        best_count = amount
                        best_depth = depth
            child = next_sibling[child]
        dominant_depth[vertex] = best_depth

fn lc_write_i64(output: UnsafePointer[UInt8, MutAnyOrigin], offset: Int, value: Int64):
    let bits = bitcast[UInt64](value)
    for byte in range(8):
        output[offset + byte] = UInt8((bits >> (8 * byte)) & UInt64(255))

@export("long_chain_dominant_depth_index")
fn long_chain_dominant_depth_index(input: UnsafePointer[Int64, ImmutAnyOrigin],
    length: c_size_t, output: UnsafePointer[UInt8, MutAnyOrigin],
    capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length == 0 or length > c_size_t(MAX_INPUT):
        return -1
    let n_value = input[0]
    if n_value < 1 or n_value > MAX_N or length != c_size_t(n_value):
        return -1
    let n = Int(n_value)
    for vertex in range(1, n):
        if input[vertex] < 0 or input[vertex] >= Int64(vertex):
            return -1
    let required = 8 * n
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(required):
        return -2

    var parent = InlineArray[Int, MAX_N](fill=0)
    for vertex in range(1, n):
        parent[vertex] = Int(input[vertex])
    var first_child = InlineArray[Int, MAX_N](fill=-1)
    var next_sibling = InlineArray[Int, MAX_N](fill=-1)
    var height = InlineArray[Int, MAX_N](fill=0)
    var heavy = InlineArray[Int, MAX_N](fill=-1)
    var base = InlineArray[Int, MAX_N](fill=0)
    var count = InlineArray[Int, MAX_N](fill=0)
    var dominant_depth = InlineArray[Int, MAX_N](fill=0)
    lc_solve(n, parent, first_child, next_sibling, height, heavy, base,
             count, dominant_depth)
    for vertex in range(n):
        lc_write_i64(output, 8 * vertex, Int64(dominant_depth[vertex]))
    return Int64(required)
