from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

fn inner_add(inout trees: InlineArray[Int64, 150], n: Int, node: Int,
             y: Int64, delta: Int64):
    var index = Int(y) + 1
    while index <= n:
        trees[node * 25 + index] += delta
        index += index & -index

fn inner_prefix(inout trees: InlineArray[Int64, 150], node: Int,
                y_limit: Int64) -> Int64:
    var index = Int(y_limit)
    var total: Int64 = 0
    while index > 0:
        total += trees[node * 25 + index]
        index &= index - 1
    return total

fn prefix_count(inout ys: InlineArray[Int64, 24],
                inout trees: InlineArray[Int64, 150], block_size: Int,
                x_limit: Int, y_limit: Int64) -> Int64:
    let full_blocks = x_limit // block_size
    var node = full_blocks
    var total: Int64 = 0
    while node > 0:
        total += inner_prefix(inout trees, node, y_limit)
        node &= node - 1
    for x in range(full_blocks * block_size, x_limit):
        if ys[x] < y_limit:
            total += 1
    return total

@export("fenwick_tree_in_block_array_rectangle_count")
fn fenwick_tree_in_block_array_rectangle_count(
    input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t
) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 2 or length > 187: return -1
    let n_value = input[0]
    let q_value = input[1]
    if n_value < 1 or n_value > 24 or q_value < 1 or q_value > 32: return -1
    let n = Int(n_value)
    let q = Int(q_value)
    let operations_at = 2 + n
    if length != c_size_t(operations_at + 5 * q): return -1

    var ys = InlineArray[Int64, 24]()
    for x in range(n):
        ys[x] = input[2 + x]
        if ys[x] < 0 or ys[x] >= n_value: return -1
    for j in range(q):
        let at = operations_at + 5 * j
        let kind = input[at]
        if kind == 0:
            if input[at + 1] < 0 or input[at + 1] >= n_value
                or input[at + 2] < 0 or input[at + 2] >= n_value
                or input[at + 3] != 0 or input[at + 4] != 0: return -1
        elif kind == 1:
            if input[at + 1] < 0 or input[at + 1] > input[at + 2]
                or input[at + 2] > n_value
                or input[at + 3] < 0 or input[at + 3] > input[at + 4]
                or input[at + 4] > n_value: return -1
        else:
            return -1

    var block_size = 1
    while block_size * block_size < n:
        block_size += 1
    let block_count = (n + block_size - 1) // block_size
    var trees = InlineArray[Int64, 150]()
    for x in range(n):
        var node = x // block_size + 1
        while node <= block_count:
            inner_add(inout trees, n, node, ys[x], 1)
            node += node & -node

    var checksum: Int64 = 0
    var query_ordinal: Int64 = 0
    for j in range(q):
        let at = operations_at + 5 * j
        if input[at] == 0:
            let x = Int(input[at + 1])
            let new_y = input[at + 2]
            var node = x // block_size + 1
            while node <= block_count:
                inner_add(inout trees, n, node, ys[x], -1)
                inner_add(inout trees, n, node, new_y, 1)
                node += node & -node
            ys[x] = new_y
        else:
            let x_left = Int(input[at + 1])
            let x_right = Int(input[at + 2])
            let y_low = input[at + 3]
            let y_high = input[at + 4]
            let count = prefix_count(inout ys, inout trees, block_size, x_right, y_high)
                - prefix_count(inout ys, inout trees, block_size, x_left, y_high)
                - prefix_count(inout ys, inout trees, block_size, x_right, y_low)
                + prefix_count(inout ys, inout trees, block_size, x_left, y_low)
            query_ordinal += 1
            checksum += query_ordinal * count
    return checksum
