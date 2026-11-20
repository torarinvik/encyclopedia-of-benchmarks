from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

alias MAX_NODES = 256
alias MAX_QUERIES = 1024
alias MAX_ARCS = 510
alias MAX_INPUT = 4 + 2 * (MAX_NODES - 1) + 2 * MAX_QUERIES

fn lowbit(value: UInt32) -> UInt32:
    if value == 0: return 0
    return value & ((~value) + UInt32(1))

fn highbit(value: UInt32) -> UInt32:
    var rest = value
    var bit: UInt32 = 0
    while rest != 0:
        bit = rest
        rest = rest >> 1
    return bit

@export("schieber_vishkin_lca")
fn schieber_vishkin_lca(
    input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
    output: UnsafePointer[UInt8, MutAnyOrigin], output_capacity: c_size_t,
) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 4 or length > MAX_INPUT + 1: return -1
    if input[0] < 1 or input[0] > MAX_NODES: return -1
    let n = Int(input[0])
    if input[1] < 0 or input[1] >= n or input[2] != n - 1 or input[3] < 0 or input[3] > MAX_QUERIES: return -1
    let m = Int(input[2])
    let q = Int(input[3])
    let query_offset = 4 + 2 * m
    if length != c_size_t(query_offset + 2 * q): return -1
    let root = Int(input[1])

    var head = InlineArray[Int, MAX_NODES]()
    var arc_to = InlineArray[Int, MAX_ARCS]()
    var arc_next = InlineArray[Int, MAX_ARCS]()
    var parent = InlineArray[Int, MAX_NODES]()
    var order = InlineArray[Int, MAX_NODES]()
    var stack_node = InlineArray[Int, MAX_NODES]()
    var stack_arc = InlineArray[Int, MAX_NODES]()
    var preorder = InlineArray[Int, MAX_NODES]()
    var inlabel = InlineArray[UInt32, MAX_NODES]()
    var ascendant = InlineArray[UInt32, MAX_NODES]()
    var path_parent = InlineArray[Int, MAX_NODES]()
    var answers = InlineArray[UInt8, MAX_QUERIES]()
    for node in range(n):
        head[node] = -1
        parent[node] = -2
    var arcs = 0
    for edge in range(m):
        let a_value = input[4 + 2 * edge]
        let b_value = input[5 + 2 * edge]
        if a_value < 0 or a_value >= n or b_value < 0 or b_value >= n or a_value == b_value: return -1
        let a = Int(a_value)
        let b = Int(b_value)
        arc_to[arcs] = b; arc_next[arcs] = head[a]; head[a] = arcs; arcs += 1
        arc_to[arcs] = a; arc_next[arcs] = head[b]; head[b] = arcs; arcs += 1
    for query in range(q):
        for side in range(2):
            let node = input[query_offset + 2 * query + side]
            if node < 0 or node >= n: return -1

    var reached = 1
    var top = 1
    parent[root] = -1; preorder[root] = 1; order[0] = root
    stack_node[0] = root; stack_arc[0] = head[root]
    while top > 0:
        let slot = top - 1
        let node = stack_node[slot]
        let arc = stack_arc[slot]
        if arc < 0:
            top -= 1
            continue
        stack_arc[slot] = arc_next[arc]
        let neighbor = arc_to[arc]
        if neighbor == parent[node]: continue
        if parent[neighbor] != -2: return -1
        parent[neighbor] = node
        preorder[neighbor] = reached + 1
        order[reached] = neighbor
        reached += 1
        stack_node[top] = neighbor
        stack_arc[top] = head[neighbor]
        top += 1
    if reached != n: return -1
    if output_capacity < c_size_t(q) or (q > 0 and output == UnsafePointer[UInt8, MutAnyOrigin]()): return -2

    for node in range(n): inlabel[node] = UInt32(preorder[node])
    var i = n
    while i > 1:
        i -= 1
        let node = order[i - 1]
        let p = parent[node]
        if lowbit(inlabel[p]) < lowbit(inlabel[node]): inlabel[p] = inlabel[node]
    for pos in range(n):
        let node = order[pos]
        if parent[node] < 0:
            ascendant[node] = lowbit(inlabel[node])
            path_parent[preorder[node] - 1] = node
        else:
            let p = parent[node]
            ascendant[node] = ascendant[p] | lowbit(inlabel[node])
            path_parent[preorder[node] - 1] = if inlabel[node] != inlabel[p]: p else: path_parent[preorder[p] - 1]

    for query in range(q):
        let u = Int(input[query_offset + 2 * query])
        let v = Int(input[query_offset + 2 * query + 1])
        let lu = lowbit(inlabel[u])
        let lv = lowbit(inlabel[v])
        var mask = highbit((inlabel[u] ^ inlabel[v]) | lu | lv) - 1
        let j = lowbit(ascendant[u] & ascendant[v] & ~mask)
        if j == 0: return -1
        var x = u
        var y = v
        if j != lu:
            mask = highbit(ascendant[u] & (j - 1)) - 1
            let index = ((preorder[u] & ~Int(mask)) | (Int(mask) + 1)) - 1
            x = path_parent[index]
        if j != lv:
            mask = highbit(ascendant[v] & (j - 1)) - 1
            let index = ((preorder[v] & ~Int(mask)) | (Int(mask) + 1)) - 1
            y = path_parent[index]
        let answer = if preorder[x] < preorder[y]: x else: y
        answers[query] = UInt8(answer)
    for query in range(q): output[query] = answers[query]
    return Int64(q)
