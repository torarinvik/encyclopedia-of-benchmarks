from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

comptime MOD = 998244353
comptime MAX_N = 32
comptime MAX_Q = 32
comptime MAX_NODES = 64
comptime MAX_INPUT = 195

struct Node(Copyable):
    var left: Int32
    var right: Int32
    var size: Int32
    var value: Int64
    var sum: Int64
    var mul: Int64
    var add: Int64
    var priority: UInt64
    var reversed: Bool

struct Operation(Copyable):
    var kind: Int32
    var left: Int
    var right: Int
    var node: Int
    var mul: Int64
    var add: Int64

fn priority_for(id: Int) -> UInt64:
    var state = Int64(1)
    for _ in range(id + 1): state = (state * 48271) % 2147483647
    return state.cast[UInt64]()

fn dsras_size(nodes: InlineArray[Node, MAX_NODES], x: Int) -> Int:
    if x < 0: return 0
    return Int(nodes[x].size)

fn dsras_sum(nodes: InlineArray[Node, MAX_NODES], x: Int) -> Int64:
    if x < 0: return 0
    return nodes[x].sum

fn dsras_higher(nodes: InlineArray[Node, MAX_NODES], a: Int, b: Int) -> Bool:
    if nodes[a].priority != nodes[b].priority: return nodes[a].priority > nodes[b].priority
    return a > b

fn dsras_pull(mut nodes: InlineArray[Node, MAX_NODES], x: Int):
    nodes[x].size = Int32(1 + dsras_size(nodes, Int(nodes[x].left)) + dsras_size(nodes, Int(nodes[x].right)))
    nodes[x].sum = (nodes[x].value + dsras_sum(nodes, Int(nodes[x].left)) + dsras_sum(nodes, Int(nodes[x].right))) % MOD

fn dsras_affine(mut nodes: InlineArray[Node, MAX_NODES], x: Int, m: Int64, a: Int64):
    if x < 0: return
    nodes[x].value = (m * nodes[x].value + a) % MOD
    nodes[x].sum = (m * nodes[x].sum + a * Int64(nodes[x].size)) % MOD
    nodes[x].mul = (m * nodes[x].mul) % MOD
    nodes[x].add = (m * nodes[x].add + a) % MOD

fn dsras_reverse(mut nodes: InlineArray[Node, MAX_NODES], x: Int):
    if x < 0: return
    let left = nodes[x].left
    nodes[x].left = nodes[x].right
    nodes[x].right = left
    nodes[x].reversed = not nodes[x].reversed

fn dsras_push(mut nodes: InlineArray[Node, MAX_NODES], x: Int):
    if nodes[x].mul != 1 or nodes[x].add != 0:
        dsras_affine(mut nodes, Int(nodes[x].left), nodes[x].mul, nodes[x].add)
        dsras_affine(mut nodes, Int(nodes[x].right), nodes[x].mul, nodes[x].add)
        nodes[x].mul = 1
        nodes[x].add = 0
    if nodes[x].reversed:
        dsras_reverse(mut nodes, Int(nodes[x].left))
        dsras_reverse(mut nodes, Int(nodes[x].right))
        nodes[x].reversed = False

fn dsras_split(mut nodes: InlineArray[Node, MAX_NODES], root: Int, count: Int,
               inout first: Int, inout second: Int):
    if root < 0:
        first = -1
        second = -1
        return
    dsras_push(mut nodes, root)
    let left = Int(nodes[root].left)
    if dsras_size(nodes, left) >= count:
        var a = 0
        var b = 0
        dsras_split(mut nodes, left, count, a, b)
        nodes[root].left = Int32(b)
        dsras_pull(mut nodes, root)
        first = a
        second = root
    else:
        var a = 0
        var b = 0
        dsras_split(mut nodes, Int(nodes[root].right), count - dsras_size(nodes, left) - 1, a, b)
        nodes[root].right = Int32(a)
        dsras_pull(mut nodes, root)
        first = root
        second = b

fn dsras_merge(mut nodes: InlineArray[Node, MAX_NODES], a: Int, b: Int) -> Int:
    if a < 0: return b
    if b < 0: return a
    if dsras_higher(nodes, a, b):
        dsras_push(mut nodes, a)
        nodes[a].right = Int32(dsras_merge(mut nodes, Int(nodes[a].right), b))
        dsras_pull(mut nodes, a)
        return a
    dsras_push(mut nodes, b)
    nodes[b].left = Int32(dsras_merge(mut nodes, a, Int(nodes[b].left)))
    dsras_pull(mut nodes, b)
    return b

fn dsras_put64(output: UnsafePointer[UInt8, MutAnyOrigin], offset: Int, value: Int64):
    let bits = value.bitcast[UInt64]()
    for j in range(8): output[offset + j] = ((bits >> (8 * j)) & 255).cast[UInt8]()

@export("dynamic_sequence_range_affine_range_sum")
fn dynamic_sequence_range_affine_range_sum(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
        output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 2 or length > MAX_INPUT: return -1
    let n_value = input[0]
    let q_value = input[1]
    if n_value < 0 or n_value > MAX_N or q_value < 0 or q_value > MAX_Q: return -1
    let n = n_value.cast[Int]()
    let q = q_value.cast[Int]()
    if length < c_size_t(2 + n): return -1
    var nodes = InlineArray[Node, MAX_NODES](fill=Node(left=-1, right=-1, size=0, value=0, sum=0, mul=1, add=0, priority=0, reversed=False))
    var offset = 2
    for i in range(n):
        let value = input[offset]
        offset += 1
        if value < 0 or value >= MOD: return -1
        nodes[i] = Node(left=-1, right=-1, size=1, value=value, sum=value, mul=1, add=0, priority=priority_for(i), reversed=False)
    var operations = InlineArray[Operation, MAX_Q](fill=Operation(kind=0, left=0, right=0, node=-1, mul=0, add=0))
    var current = n
    var node_count = n
    var query_count = 0
    for i in range(q):
        if c_size_t(offset) >= length: return -1
        let tag = input[offset]
        offset += 1
        if tag < 0 or tag > 4: return -1
        var op = Operation(kind=tag.cast[Int32](), left=0, right=0, node=-1, mul=0, add=0)
        if tag == 0:
            if c_size_t(offset + 2) > length: return -1
            let at = input[offset]
            let value = input[offset + 1]
            offset += 2
            if at < 0 or at.cast[UInt64]() > current.cast[UInt64]() or current >= MAX_NODES or value < 0 or value >= MOD: return -1
            op.left = at.cast[Int]()
            op.node = node_count
            nodes[node_count] = Node(left=-1, right=-1, size=1, value=value, sum=value, mul=1, add=0, priority=priority_for(node_count), reversed=False)
            node_count += 1
            current += 1
        elif tag == 1:
            if c_size_t(offset + 1) > length: return -1
            let at = input[offset]
            offset += 1
            if at < 0 or at.cast[UInt64]() >= current.cast[UInt64](): return -1
            op.left = at.cast[Int]()
            current -= 1
        elif tag == 2 or tag == 4:
            if c_size_t(offset + 2) > length: return -1
            let left = input[offset]
            let right = input[offset + 1]
            offset += 2
            if left < 0 or left > right or right.cast[UInt64]() > current.cast[UInt64](): return -1
            op.left = left.cast[Int]()
            op.right = right.cast[Int]()
            if tag == 4: query_count += 1
        else:
            if c_size_t(offset + 4) > length: return -1
            let left = input[offset]
            let right = input[offset + 1]
            let mul = input[offset + 2]
            let add = input[offset + 3]
            offset += 4
            if left < 0 or left > right or right.cast[UInt64]() > current.cast[UInt64]() or mul < 0 or mul >= MOD or add < 0 or add >= MOD: return -1
            op.left = left.cast[Int]()
            op.right = right.cast[Int]()
            op.mul = mul
            op.add = add
        operations[i] = op
    if c_size_t(offset) != length: return -1
    var root = -1
    for i in range(n): root = dsras_merge(mut nodes, root, i)
    var answers = InlineArray[Int64, MAX_Q](fill=0)
    var answer_count = 0
    for i in range(q):
        let op = operations[i]
        var prefix = 0
        var suffix = 0
        dsras_split(mut nodes, root, op.left, prefix, suffix)
        if op.kind == 0:
            root = dsras_merge(mut nodes, dsras_merge(mut nodes, prefix, op.node), suffix)
            continue
        var middle = 0
        var tail = 0
        if op.kind == 1:
            dsras_split(mut nodes, suffix, 1, middle, tail)
            root = dsras_merge(mut nodes, prefix, tail)
            continue
        else:
            dsras_split(mut nodes, suffix, op.right - op.left, middle, tail)
            if op.kind == 2: dsras_reverse(mut nodes, middle)
            elif op.kind == 3: dsras_affine(mut nodes, middle, op.mul, op.add)
            else:
                answers[answer_count] = dsras_sum(nodes, middle)
                answer_count += 1
        root = dsras_merge(mut nodes, dsras_merge(mut nodes, prefix, middle), tail)
    let bytes = 8 * query_count
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(bytes): return -2
    for i in range(query_count): dsras_put64(output, 8 * i, answers[i])
    return bytes.cast[Int64]()
