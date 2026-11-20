from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

fn lsamr_apply(mut tree: InlineArray[Int64, 64], mut pending: InlineArray[Int64, 64],
               node: Int, segment_length: Int, delta: Int64):
    tree[node] += delta * Int64(segment_length)
    pending[node] += delta

fn lsamr_push(mut tree: InlineArray[Int64, 64], mut pending: InlineArray[Int64, 64],
              node: Int, segment_length: Int):
    if segment_length > 1 and pending[node] != 0:
        let half = segment_length / 2
        let delta = pending[node]
        lsamr_apply(tree, pending, 2 * node, half, delta)
        lsamr_apply(tree, pending, 2 * node + 1, half, delta)
        pending[node] = 0

fn lsamr_add(mut tree: InlineArray[Int64, 64], mut pending: InlineArray[Int64, 64],
             node: Int, low: Int, high: Int, query_low: Int, query_high: Int, delta: Int64):
    if query_low >= query_high: return
    if query_high <= low or high <= query_low: return
    if query_low <= low and high <= query_high:
        lsamr_apply(tree, pending, node, high - low, delta)
        return
    lsamr_push(tree, pending, node, high - low)
    let middle = (low + high) / 2
    if query_low < middle:
        lsamr_add(tree, pending, 2 * node, low, middle, query_low, query_high, delta)
    if query_high > middle:
        lsamr_add(tree, pending, 2 * node + 1, middle, high, query_low, query_high, delta)
    tree[node] = tree[2 * node] + tree[2 * node + 1]

fn lsamr_max_right(mut tree: InlineArray[Int64, 64], mut pending: InlineArray[Int64, 64],
                   node: Int, low: Int, high: Int, n: Int, left: Int,
                   limit: Int64, mut accumulated: Int64) -> Int:
    if high <= left: return high
    if low >= n: return n
    if left <= low and high <= n and accumulated + tree[node] <= limit:
        accumulated += tree[node]
        return high
    if high - low == 1: return low
    lsamr_push(tree, pending, node, high - low)
    let middle = (low + high) / 2
    let first = lsamr_max_right(tree, pending, 2 * node, low, middle, n, left, limit, accumulated)
    if first < middle and first >= left: return first
    return lsamr_max_right(tree, pending, 2 * node + 1, middle, high, n, left, limit, accumulated)

@export("lazy_segment_tree_range_add_max_right")
fn lazy_segment_tree_range_add_max_right(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 3 or length > 67: return -1
    if input[0] < 1 or input[0] > 16 or input[1] < 0 or input[1] > 12: return -1
    let n = Int(input[0])
    let operations = Int(input[1])
    if length != c_size_t(2 + n + 4 * operations) or length > 66: return -1
    for i in range(n):
        if input[2 + i] < 0 or input[2 + i] > 31: return -1
    for operation in range(operations):
        let p = 2 + n + 4 * operation
        let opcode = input[p]
        let left = input[p + 1]
        let right = input[p + 2]
        let extra = input[p + 3]
        if opcode == 0:
            if left < 0 or left > Int64(n) or right < left or right > Int64(n) or extra < 0 or extra > 31: return -1
        elif opcode == 1:
            if left < 0 or left > Int64(n) or right < 0 or right > 8192 or extra != 0: return -1
        else:
            return -1

    var base = 1
    while base < n: base *= 2
    var tree = InlineArray[Int64, 64](fill=0)
    var pending = InlineArray[Int64, 64](fill=0)
    for i in range(n): tree[base + i] = input[2 + i]
    var node = base
    while node > 1:
        node -= 1
        tree[node] = tree[2 * node] + tree[2 * node + 1]

    var query_index = 0
    var result: Int64 = 0
    for operation in range(operations):
        let p = 2 + n + 4 * operation
        let left = Int(input[p + 1])
        let right = Int(input[p + 2])
        if input[p] == 0:
            lsamr_add(tree, pending, 1, 0, base, left, right, input[p + 3])
        else:
            var accumulated: Int64 = 0
            let boundary = lsamr_max_right(tree, pending, 1, 0, base, n, left, Int64(right), accumulated)
            result |= Int64(boundary) << (5 * query_index)
            query_index += 1
    return result
