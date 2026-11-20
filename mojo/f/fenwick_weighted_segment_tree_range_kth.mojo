from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

comptime FWK_MAX_N = 12
comptime FWK_MAX_Q = 16
comptime FWK_VALUE_COUNT = 61
comptime FWK_NODE_CAPACITY = 1280

fn fwk_change(inout left: InlineArray[Int, FWK_NODE_CAPACITY + 1],
              inout right: InlineArray[Int, FWK_NODE_CAPACITY + 1],
              inout count: InlineArray[Int, FWK_NODE_CAPACITY + 1],
              inout used: Int, root_arg: Int, low: Int, high: Int,
              coordinate: Int, delta: Int) -> Int:
    var root = root_arg
    if root == 0:
        used += 1
        root = used
    count[root] += delta
    if high - low > 1:
        let middle = (low + high) / 2
        if coordinate < middle:
            let child = fwk_change(left, right, count, used, left[root], low, middle, coordinate, delta)
            left[root] = child
        else:
            let child = fwk_change(left, right, count, used, right[root], middle, high, coordinate, delta)
            right[root] = child
    return root

fn fwk_apply(inout left: InlineArray[Int, FWK_NODE_CAPACITY + 1],
             inout right: InlineArray[Int, FWK_NODE_CAPACITY + 1],
             inout count: InlineArray[Int, FWK_NODE_CAPACITY + 1],
             inout used: Int, inout roots: InlineArray[Int, FWK_MAX_N + 1],
             n: Int, position: Int, value: Int, delta: Int):
    var node = position + 1
    while node <= n:
        let root = fwk_change(left, right, count, used, roots[node], 0,
                              FWK_VALUE_COUNT, value + 30, delta)
        roots[node] = root
        node += node & -node

@export("fenwick_weighted_segment_tree_range_kth")
fn fenwick_weighted_segment_tree_range_kth(
    input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t
) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 3 or length > 79:
        return -9223372036854775807 - 1
    let n_value = input[0]
    let q_value = input[1]
    if n_value < 1 or n_value > FWK_MAX_N or q_value < 0 or q_value > FWK_MAX_Q:
        return -9223372036854775807 - 1
    let n = Int(n_value)
    let q = Int(q_value)
    if length != c_size_t(2 + n + 4 * q): return -9223372036854775807 - 1

    var current = InlineArray[Int, FWK_MAX_N](fill=0)
    var roots = InlineArray[Int, FWK_MAX_N + 1](fill=0)
    var left = InlineArray[Int, FWK_NODE_CAPACITY + 1](fill=0)
    var right = InlineArray[Int, FWK_NODE_CAPACITY + 1](fill=0)
    var count = InlineArray[Int, FWK_NODE_CAPACITY + 1](fill=0)
    var used = 0
    for position in range(n):
        let value = input[2 + position]
        if value < -30 or value > 30: return -9223372036854775807 - 1
        current[position] = Int(value)
        fwk_apply(left, right, count, used, roots, n, position, Int(value), 1)

    var checksum: Int64 = 0
    var query_number = 0
    var cursor = 2 + n
    for _ in range(q):
        let opcode = input[cursor]
        let first = input[cursor + 1]
        let second = input[cursor + 2]
        let third = input[cursor + 3]
        cursor += 4
        if opcode == 0:
            if first < 0 or first >= n_value or second < -30 or second > 30 or third != 0:
                return -9223372036854775807 - 1
            let position = Int(first)
            fwk_apply(left, right, count, used, roots, n, position, current[position], -1)
            current[position] = Int(second)
            fwk_apply(left, right, count, used, roots, n, position, current[position], 1)
        elif opcode == 1:
            if first < 0 or first >= second or second > n_value or third < 1 or third > second - first:
                return -9223372036854775807 - 1
            var left_roots = InlineArray[Int, FWK_MAX_N + 1](fill=0)
            var right_roots = InlineArray[Int, FWK_MAX_N + 1](fill=0)
            var left_size = 0
            var right_size = 0
            var node = Int(first)
            while node > 0:
                left_roots[left_size] = roots[node]
                left_size += 1
                node -= node & -node
            node = Int(second)
            while node > 0:
                right_roots[right_size] = roots[node]
                right_size += 1
                node -= node & -node
            var low = 0
            var high = FWK_VALUE_COUNT
            var rank = Int(third)
            while high - low > 1:
                let middle = (low + high) / 2
                var left_count = 0
                for i in range(right_size): left_count += count[left[right_roots[i]]]
                for i in range(left_size): left_count -= count[left[left_roots[i]]]
                if rank <= left_count:
                    for i in range(right_size): right_roots[i] = left[right_roots[i]]
                    for i in range(left_size): left_roots[i] = left[left_roots[i]]
                    high = middle
                else:
                    rank -= left_count
                    for i in range(right_size): right_roots[i] = right[right_roots[i]]
                    for i in range(left_size): left_roots[i] = right[left_roots[i]]
                    low = middle
            query_number += 1
            checksum += Int64(query_number) * Int64(low - 30)
        else:
            return -9223372036854775807 - 1
    return checksum
