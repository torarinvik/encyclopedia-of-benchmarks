from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

comptime MAX_N = 64
comptime MAX_Q = 32
comptime MAX_INPUT = 163

struct Node(Copyable):
    var left: Int32
    var right: Int32
    var size: Int32
    var value: Int64
    var sum: Int64
    var priority: UInt64
    var reversed: Bool

struct Operation(Copyable):
    var kind: Int64
    var left: Int
    var right: Int

fn priority_for(index: Int) -> UInt64:
    var state = Int64(1)
    for _ in range(index + 1): state = (state * 48271) % 2147483647
    return state.cast[UInt64]()

fn rrs_size(nodes: InlineArray[Node, MAX_N], x: Int) -> Int:
    if x < 0: return 0
    return nodes[x].size

fn rrs_sum(nodes: InlineArray[Node, MAX_N], x: Int) -> Int64:
    if x < 0: return 0
    return nodes[x].sum

fn rrs_higher(nodes: InlineArray[Node, MAX_N], a: Int, b: Int) -> Bool:
    if nodes[a].priority != nodes[b].priority: return nodes[a].priority > nodes[b].priority
    return a > b

fn rrs_pull(mut nodes: InlineArray[Node, MAX_N], x: Int):
    nodes[x].size = 1 + rrs_size(nodes, Int(nodes[x].left)) + rrs_size(nodes, Int(nodes[x].right))
    nodes[x].sum = nodes[x].value + rrs_sum(nodes, Int(nodes[x].left)) + rrs_sum(nodes, Int(nodes[x].right))

fn rrs_reverse(mut nodes: InlineArray[Node, MAX_N], x: Int):
    if x < 0: return
    let left = nodes[x].left
    nodes[x].left = nodes[x].right
    nodes[x].right = left
    nodes[x].reversed = not nodes[x].reversed

fn rrs_push(mut nodes: InlineArray[Node, MAX_N], x: Int):
    if not nodes[x].reversed: return
    let left = Int(nodes[x].left)
    let right = Int(nodes[x].right)
    rrs_reverse(mut nodes, left)
    rrs_reverse(mut nodes, right)
    nodes[x].reversed = False

fn rrs_split(mut nodes: InlineArray[Node, MAX_N], root: Int, count: Int,
              inout first: Int, inout second: Int):
    if root < 0:
        first = -1
        second = -1
        return
    rrs_push(mut nodes, root)
    let left = Int(nodes[root].left)
    if rrs_size(nodes, left) >= count:
        var a = 0
        var b = 0
        rrs_split(mut nodes, left, count, a, b)
        nodes[root].left = Int32(b)
        rrs_pull(mut nodes, root)
        first = a
        second = root
    else:
        var a = 0
        var b = 0
        rrs_split(mut nodes, Int(nodes[root].right),
                  count - rrs_size(nodes, left) - 1, a, b)
        nodes[root].right = Int32(a)
        rrs_pull(mut nodes, root)
        first = root
        second = b

fn rrs_merge(mut nodes: InlineArray[Node, MAX_N], a: Int, b: Int) -> Int:
    if a < 0: return b
    if b < 0: return a
    if rrs_higher(nodes, a, b):
        rrs_push(mut nodes, a)
        nodes[a].right = Int32(rrs_merge(mut nodes, Int(nodes[a].right), b))
        rrs_pull(mut nodes, a)
        return a
    rrs_push(mut nodes, b)
    nodes[b].left = Int32(rrs_merge(mut nodes, a, Int(nodes[b].left)))
    rrs_pull(mut nodes, b)
    return b

fn rrs_put64(output: UnsafePointer[UInt8, MutAnyOrigin], offset: Int, value: Int64):
    let bits = value.bitcast[UInt64]()
    for j in range(8): output[offset + j] = ((bits >> (8 * j)) & 255).cast[UInt8]()

@export("range_reverse_range_sum")
fn range_reverse_range_sum(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
                           output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 2 or length > MAX_INPUT: return -1
    let n_value = input[0]
    let q_value = input[1]
    if n_value < 0 or n_value > MAX_N or q_value < 0 or q_value > MAX_Q: return -1
    let n = n_value.cast[Int]()
    let q = q_value.cast[Int]()
    if length < c_size_t(2 + n): return -1
    var nodes = InlineArray[Node, MAX_N](fill=Node(left=-1, right=-1, size=0, value=0, sum=0, priority=0, reversed=False))
    var offset = 2
    for i in range(n):
        let value = input[offset]
        offset += 1
        if value < 0 or value > 1000000000: return -1
        nodes[i] = Node(left=-1, right=-1, size=1, value=value, sum=value,
                        priority=priority_for(i), reversed=False)
    var operations = InlineArray[Operation, MAX_Q](fill=Operation(kind=0, left=0, right=0))
    var query_count = 0
    for i in range(q):
        if c_size_t(offset + 3) > length: return -1
        let kind = input[offset]
        let left = input[offset + 1]
        let right = input[offset + 2]
        offset += 3
        if (kind != 0 and kind != 1) or left < 0 or left > right or right > n_value: return -1
        operations[i].kind = kind
        operations[i].left = left.cast[Int]()
        operations[i].right = right.cast[Int]()
        if kind == 1: query_count += 1
    if c_size_t(offset) != length: return -1
    var root = -1
    for i in range(n): root = rrs_merge(mut nodes, root, i)
    var answers = InlineArray[Int64, MAX_Q](fill=0)
    var answer_count = 0
    for i in range(q):
        let op = operations[i]
        var prefix = 0
        var suffix = 0
        rrs_split(mut nodes, root, op.right, prefix, suffix)
        var first = 0
        var middle = 0
        rrs_split(mut nodes, prefix, op.left, first, middle)
        prefix = first
        if op.kind == 0: rrs_reverse(mut nodes, middle)
        else:
            answers[answer_count] = rrs_sum(nodes, middle)
            answer_count += 1
        root = rrs_merge(mut nodes, rrs_merge(mut nodes, prefix, middle), suffix)
    let bytes = 8 * query_count
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(bytes): return -2
    for i in range(query_count): rrs_put64(output, 8 * i, answers[i])
    return bytes.cast[Int64]()
