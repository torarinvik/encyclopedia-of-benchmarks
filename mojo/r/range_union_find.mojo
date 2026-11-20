from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

comptime MAX_N = 32
comptime MAX_Q = 32
comptime MAX_PARSEABLE_LENGTH = 99

fn ruf_find(mut parent: InlineArray[Int64, 32], vertex_input: Int) -> Int:
    var vertex = vertex_input
    while parent[vertex] >= 0:
        let ancestor = Int(parent[vertex])
        if parent[ancestor] >= 0: parent[vertex] = parent[ancestor]
        vertex = ancestor
    return vertex

fn ruf_unite_roots(
    mut parent: InlineArray[Int64, 32],
    mut left: InlineArray[Int64, 32],
    mut right: InlineArray[Int64, 32],
    root_a_input: Int, root_b_input: Int,
) -> Int:
    var root_a = root_a_input
    var root_b = root_b_input
    if parent[root_a] > parent[root_b]:
        let temporary = root_a
        root_a = root_b
        root_b = temporary
    parent[root_a] += parent[root_b]
    parent[root_b] = Int64(root_a)
    left[root_a] = min(left[root_a], left[root_b])
    right[root_a] = max(right[root_a], right[root_b])
    return root_a

@export("range_union_find")
fn range_union_find(values: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t) abi("C") -> Int64:
    if values == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 2 or
       length > c_size_t(MAX_PARSEABLE_LENGTH): return -1
    let n_value = values[0]
    let q_value = values[1]
    if n_value < 1 or n_value > MAX_N or q_value < 0 or q_value > MAX_Q or
       length != c_size_t(2 + 3 * q_value): return -1
    let n = Int(n_value)
    let q = Int(q_value)
    for operation in range(q):
        let offset = 2 + 3 * operation
        let opcode = values[offset]
        let first = values[offset + 1]
        let second = values[offset + 2]
        if opcode == 0:
            if first < 0 or first > second or second > n_value: return -1
        elif opcode == 1:
            if first < 0 or first >= n_value or second < 0 or second >= n_value: return -1
        elif opcode == 2:
            if first < 0 or first >= n_value or second != 0: return -1
        else:
            return -1

    var parent = InlineArray[Int64, 32](fill=-1)
    var left = InlineArray[Int64, 32](fill=0)
    var right = InlineArray[Int64, 32](fill=0)
    for vertex in range(n):
        left[vertex] = Int64(vertex)
        right[vertex] = Int64(vertex + 1)
    var components = n
    var total: Int64 = 0
    for operation in range(q):
        let offset = 2 + 3 * operation
        let opcode = values[offset]
        let first = Int(values[offset + 1])
        let second = Int(values[offset + 2])
        var observed: Int64 = 0
        if opcode == 0:
            if first < second:
                var root = ruf_find(mut parent, first)
                var next = Int(right[root])
                while next < second:
                    let next_root = ruf_find(mut parent, next)
                    if root == next_root: break
                    root = ruf_unite_roots(mut parent, mut left, mut right, root, next_root)
                    components -= 1
                    next = Int(right[root])
            observed = Int64(components)
        elif opcode == 1:
            if ruf_find(mut parent, first) == ruf_find(mut parent, second):
                observed = 1
            else:
                observed = 0
        else:
            observed = -parent[ruf_find(mut parent, first)]
        total += Int64(operation + 1) * observed
    return total
