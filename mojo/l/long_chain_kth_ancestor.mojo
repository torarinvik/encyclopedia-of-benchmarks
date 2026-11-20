from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

comptime MAX_N = 64
comptime MAX_Q = 32
comptime LOG_LEVELS = 6

fn lca_solve(n: Int, parent: InlineArray[Int, MAX_N],
             inout depth: InlineArray[Int, MAX_N],
             inout height: InlineArray[Int, MAX_N],
             inout heavy: InlineArray[Int, MAX_N],
             inout chain_head: InlineArray[Int, MAX_N],
             inout chain_position: InlineArray[Int, MAX_N],
             inout chain_base: InlineArray[Int, MAX_N],
             inout chain_nodes: InlineArray[Int, MAX_N],
             inout head_ancestors: InlineArray[Int, MAX_N],
             inout up: InlineArray[Int, 384]):
    for vertex in range(n):
        heavy[vertex] = -1
        chain_head[vertex] = -1
        chain_base[vertex] = -1
        height[vertex] = 1
        if vertex > 0:
            depth[vertex] = depth[parent[vertex]] + 1

    for reverse in range(1, n):
        let vertex = n - reverse
        let p = parent[vertex]
        let old = heavy[p]
        if old < 0 or height[vertex] > height[old] or
           (height[vertex] == height[old] and vertex < old):
            heavy[p] = vertex
        height[p] = max(height[p], height[vertex] + 1)

    var pool = 0
    for vertex in range(n):
        var is_head = vertex == 0
        if vertex > 0:
            is_head = heavy[parent[vertex]] != vertex
        if is_head:
            chain_base[vertex] = pool
            var current = vertex
            var position = 0
            while current >= 0:
                chain_head[current] = vertex
                chain_position[current] = position
                chain_nodes[pool + position] = current
                current = heavy[current]
                position += 1
            current = parent[vertex]
            for step in range(position):
                head_ancestors[pool + step] = current
                if current >= 0:
                    current = parent[current]
                else:
                    current = -1
            pool += position

    for vertex in range(n):
        up[vertex] = parent[vertex]
    for level in range(1, LOG_LEVELS):
        for vertex in range(n):
            let halfway = up[(level - 1) * MAX_N + vertex]
            if halfway >= 0:
                up[level * MAX_N + vertex] = up[(level - 1) * MAX_N + halfway]
            else:
                up[level * MAX_N + vertex] = -1

fn lca_write_i64(output: UnsafePointer[UInt8, MutAnyOrigin], offset: Int, value: Int64):
    let bits = bitcast[UInt64](value)
    for byte in range(8):
        output[offset + byte] = UInt8((bits >> (8 * byte)) & UInt64(255))

@export("long_chain_kth_ancestor")
fn long_chain_kth_ancestor(input: UnsafePointer[Int64, ImmutAnyOrigin],
    length: c_size_t, output: UnsafePointer[UInt8, MutAnyOrigin],
    capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 2 or length > c_size_t(130):
        return -1
    let n_value = input[0]
    let q_value = input[1]
    if n_value < 1 or n_value > MAX_N or q_value < 1 or q_value > MAX_Q:
        return -1
    let n = Int(n_value)
    let q = Int(q_value)
    if length != c_size_t(n + 1 + 2 * q):
        return -1
    for vertex in range(1, n):
        if input[1 + vertex] < 0 or input[1 + vertex] >= Int64(vertex):
            return -1
    let query_start = n + 1
    for query in range(q):
        let vertex = input[query_start + 2 * query]
        let distance = input[query_start + 2 * query + 1]
        if vertex < 0 or vertex >= n_value or distance < 0 or distance >= MAX_N:
            return -1
    let required = 8 * q
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(required):
        return -2

    var parent = InlineArray[Int, MAX_N](fill=-1)
    var depth = InlineArray[Int, MAX_N](fill=0)
    var height = InlineArray[Int, MAX_N](fill=0)
    var heavy = InlineArray[Int, MAX_N](fill=-1)
    var chain_head = InlineArray[Int, MAX_N](fill=-1)
    var chain_position = InlineArray[Int, MAX_N](fill=0)
    var chain_base = InlineArray[Int, MAX_N](fill=-1)
    var chain_nodes = InlineArray[Int, MAX_N](fill=0)
    var head_ancestors = InlineArray[Int, MAX_N](fill=-1)
    var up = InlineArray[Int, 384](fill=-1)
    parent[0] = -1
    for vertex in range(1, n):
        parent[vertex] = Int(input[1 + vertex])
    lca_solve(n, parent, depth, height, heavy, chain_head, chain_position,
              chain_base, chain_nodes, head_ancestors, up)

    for query in range(q):
        let vertex = Int(input[query_start + 2 * query])
        let distance = Int(input[query_start + 2 * query + 1])
        var answer: Int64 = -1
        if distance <= depth[vertex]:
            if distance == 0:
                answer = Int64(vertex)
            else:
                var level = 0
                var value = distance
                while value > 1:
                    level += 1
                    value >>= 1
                let jumped = up[level * MAX_N + vertex]
                let remaining = distance - (1 << level)
                let head = chain_head[jumped]
                let position = chain_position[jumped]
                let base = chain_base[head]
                if remaining <= position:
                    answer = Int64(chain_nodes[base + position - remaining])
                else:
                    let steps = remaining - position
                    if steps <= height[head]:
                        answer = Int64(head_ancestors[base + steps - 1])
        lca_write_i64(output, 8 * query, answer)
    return Int64(required)
