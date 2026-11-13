from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

alias INF = Int64(2305843009213693951)

struct BeatsNode(Copyable):
    var sum: Int64 = 0
    var max1: Int64 = 0
    var max2: Int64 = -INF
    var min1: Int64 = 0
    var min2: Int64 = INF
    var add: Int64 = 0
    var max_count: Int = 0
    var min_count: Int = 0

fn beats_pull(mut tree: InlineArray[BeatsNode, 256], node: Int):
    let left = tree[2 * node]
    let right = tree[2 * node + 1]
    tree[node].sum = left.sum + right.sum
    tree[node].add = 0
    if left.max1 == right.max1:
        tree[node].max1 = left.max1
        tree[node].max2 = max(left.max2, right.max2)
        tree[node].max_count = left.max_count + right.max_count
    elif left.max1 > right.max1:
        tree[node].max1 = left.max1
        tree[node].max2 = max(left.max2, right.max1)
        tree[node].max_count = left.max_count
    else:
        tree[node].max1 = right.max1
        tree[node].max2 = max(left.max1, right.max2)
        tree[node].max_count = right.max_count
    if left.min1 == right.min1:
        tree[node].min1 = left.min1
        tree[node].min2 = min(left.min2, right.min2)
        tree[node].min_count = left.min_count + right.min_count
    elif left.min1 < right.min1:
        tree[node].min1 = left.min1
        tree[node].min2 = min(left.min2, right.min1)
        tree[node].min_count = left.min_count
    else:
        tree[node].min1 = right.min1
        tree[node].min2 = min(left.min1, right.min2)
        tree[node].min_count = right.min_count

fn beats_build(mut tree: InlineArray[BeatsNode, 256], input: UnsafePointer[Int64, ImmutAnyOrigin], node: Int, low: Int, high: Int):
    if high - low == 1:
        let value = input[low + 1]
        tree[node].sum = value
        tree[node].min1 = value
        tree[node].max1 = value
        tree[node].min_count = 1
        tree[node].max_count = 1
        return
    let middle = low + (high - low) // 2
    beats_build(mut tree, input, 2 * node, low, middle)
    beats_build(mut tree, input, 2 * node + 1, middle, high)
    beats_pull(mut tree, node)

fn beats_add(mut tree: InlineArray[BeatsNode, 256], node: Int, size: Int, delta: Int64):
    tree[node].sum += Int64(size) * delta
    tree[node].max1 += delta
    tree[node].min1 += delta
    if tree[node].max2 != -INF: tree[node].max2 += delta
    if tree[node].min2 != INF: tree[node].min2 += delta
    tree[node].add += delta

fn beats_min(mut tree: InlineArray[BeatsNode, 256], node: Int, ceiling: Int64):
    let item = tree[node]
    if item.max1 <= ceiling: return
    tree[node].sum += (ceiling - item.max1) * Int64(item.max_count)
    if item.min1 == item.max1: tree[node].min1 = ceiling
    elif item.min2 == item.max1: tree[node].min2 = ceiling
    tree[node].max1 = ceiling

fn beats_max(mut tree: InlineArray[BeatsNode, 256], node: Int, floor: Int64):
    let item = tree[node]
    if item.min1 >= floor: return
    tree[node].sum += (floor - item.min1) * Int64(item.min_count)
    if item.max1 == item.min1: tree[node].max1 = floor
    elif item.max2 == item.min1: tree[node].max2 = floor
    tree[node].min1 = floor

fn beats_push(mut tree: InlineArray[BeatsNode, 256], node: Int, low: Int, high: Int):
    if high - low == 1: return
    let middle = low + (high - low) // 2
    let delta = tree[node].add
    if delta != 0:
        beats_add(mut tree, 2 * node, middle - low, delta)
        beats_add(mut tree, 2 * node + 1, high - middle, delta)
        tree[node].add = 0
    let ceiling = tree[node].max1
    let floor = tree[node].min1
    beats_min(mut tree, 2 * node, ceiling)
    beats_min(mut tree, 2 * node + 1, ceiling)
    beats_max(mut tree, 2 * node, floor)
    beats_max(mut tree, 2 * node + 1, floor)

fn beats_update(mut tree: InlineArray[BeatsNode, 256], node: Int, low: Int, high: Int,
                ql: Int, qr: Int, operation: Int64, value: Int64):
    if qr <= low or high <= ql: return
    if operation == 0 and tree[node].max1 <= value: return
    if operation == 1 and tree[node].min1 >= value: return
    if operation == 2 and value == 0: return
    if ql <= low and high <= qr:
        if operation == 2:
            beats_add(mut tree, node, high - low, value)
            return
        if operation == 0 and tree[node].max2 < value:
            beats_min(mut tree, node, value)
            return
        if operation == 1 and tree[node].min2 > value:
            beats_max(mut tree, node, value)
            return
    beats_push(mut tree, node, low, high)
    let middle = low + (high - low) // 2
    beats_update(mut tree, 2 * node, low, middle, ql, qr, operation, value)
    beats_update(mut tree, 2 * node + 1, middle, high, ql, qr, operation, value)
    beats_pull(mut tree, node)

fn beats_sum(mut tree: InlineArray[BeatsNode, 256], node: Int, low: Int, high: Int, ql: Int, qr: Int) -> Int64:
    if qr <= low or high <= ql: return 0
    if ql <= low and high <= qr: return tree[node].sum
    beats_push(mut tree, node, low, high)
    let middle = low + (high - low) // 2
    let left_sum = beats_sum(mut tree, 2 * node, low, middle, ql, qr)
    let right_sum = beats_sum(mut tree, 2 * node + 1, middle, high, ql, qr)
    return left_sum + right_sum

@export("segment_tree_beats")
fn segment_tree_beats(values: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t) abi("C") -> Int64:
    if values == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 2 or length > 578: return -1
    let n64 = values[0]
    if n64 < 1 or n64 > 64: return -1
    let n = Int(n64)
    if length < c_size_t(n + 2): return -1
    let q64 = values[n + 1]
    if q64 < 0 or q64 > 128 or length != c_size_t(n + 2 + 4 * Int(q64)): return -1
    for i in range(n):
        if values[i + 1] < -1000000 or values[i + 1] > 1000000: return -1
    for i in range(Int(q64)):
        let pos = n + 2 + 4 * i
        let op = values[pos]
        let left = values[pos + 1]
        let right = values[pos + 2]
        let argument = values[pos + 3]
        if op < 0 or op > 3 or left < 0 or left >= right or right > n64: return -1
        if op == 3:
            if argument != 0: return -1
        elif argument < -1000000 or argument > 1000000: return -1
    var tree = InlineArray[BeatsNode, 256](fill=BeatsNode())
    beats_build(mut tree, values, 1, 0, n)
    var checksum: Int64 = 0
    var query: Int64 = 0
    for i in range(Int(q64)):
        let pos = n + 2 + 4 * i
        let op = values[pos]
        let left = Int(values[pos + 1])
        let right = Int(values[pos + 2])
        if op == 3:
            query += 1
            checksum += query * (beats_sum(mut tree, 1, 0, n, left, right) + 8256000001)
        else:
            beats_update(mut tree, 1, 0, n, left, right, op, values[pos + 3])
    return checksum
