from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

alias MAX_N = 32
alias MAX_Q = 64
alias NODE_FIELDS = 7 * MAX_N
alias MAX_INPUT = 3 * MAX_N + 5 * MAX_Q + 1
alias MAX_VALUE = 1_000

fn field(slot: Int, vertex: Int) -> Int:
    slot * MAX_N + vertex

fn lct_aux_root(nodes: InlineArray[Int64, NODE_FIELDS], x: Int) -> Bool:
    let p = Int(nodes[field(2, x)])
    p < 0 or (nodes[field(0, p)] != x and nodes[field(1, p)] != x)

fn lct_sum(nodes: InlineArray[Int64, NODE_FIELDS], x: Int) -> Int64:
    if x < 0: return 0
    nodes[field(6, x)]

fn lct_pull(mut nodes: InlineArray[Int64, NODE_FIELDS], x: Int):
    nodes[field(6, x)] = nodes[field(4, x)] + nodes[field(5, x)] + lct_sum(nodes, Int(nodes[field(0, x)])) + lct_sum(nodes, Int(nodes[field(1, x)]))

fn lct_reverse(mut nodes: InlineArray[Int64, NODE_FIELDS], x: Int):
    if x < 0: return
    let temporary = nodes[field(0, x)]
    nodes[field(0, x)] = nodes[field(1, x)]
    nodes[field(1, x)] = temporary
    nodes[field(3, x)] = 1 - nodes[field(3, x)]

fn lct_push(mut nodes: InlineArray[Int64, NODE_FIELDS], x: Int):
    if nodes[field(3, x)] == 0: return
    lct_reverse(mut nodes, Int(nodes[field(0, x)]))
    lct_reverse(mut nodes, Int(nodes[field(1, x)]))
    nodes[field(3, x)] = 0

fn lct_rotate(mut nodes: InlineArray[Int64, NODE_FIELDS], x: Int):
    let p = Int(nodes[field(2, x)])
    let g = Int(nodes[field(2, p)])
    let direction = Int(nodes[field(1, p)] == x)
    let middle = Int(nodes[field(direction ^ 1, x)])
    if not lct_aux_root(nodes, p):
        let side = Int(nodes[field(1, g)] == p)
        nodes[field(side, g)] = x
    nodes[field(2, x)] = g
    nodes[field(direction ^ 1, x)] = p
    nodes[field(2, p)] = x
    nodes[field(direction, p)] = middle
    if middle >= 0: nodes[field(2, middle)] = p
    lct_pull(mut nodes, p)
    lct_pull(mut nodes, x)

fn lct_splay(mut nodes: InlineArray[Int64, NODE_FIELDS], x: Int):
    var stack = InlineArray[Int, MAX_N]()
    var count = 1
    var y = x
    stack[0] = y
    while not lct_aux_root(nodes, y):
        y = Int(nodes[field(2, y)])
        stack[count] = y
        count += 1
    while count > 0:
        count -= 1
        lct_push(mut nodes, stack[count])
    while not lct_aux_root(nodes, x):
        let p = Int(nodes[field(2, x)])
        if not lct_aux_root(nodes, p):
            let g = Int(nodes[field(2, p)])
            let zigzig = (nodes[field(0, p)] == x) == (nodes[field(0, g)] == p)
            lct_rotate(mut nodes, if zigzig: p else: x)
        lct_rotate(mut nodes, x)

fn lct_access(mut nodes: InlineArray[Int64, NODE_FIELDS], x: Int):
    var last = -1
    var y = x
    while y >= 0:
        lct_splay(mut nodes, y)
        let old_right = Int(nodes[field(1, y)])
        nodes[field(5, y)] += lct_sum(nodes, old_right) - lct_sum(nodes, last)
        nodes[field(1, y)] = last
        if last >= 0: nodes[field(2, last)] = y
        lct_pull(mut nodes, y)
        last = y
        y = Int(nodes[field(2, y)])
    lct_splay(mut nodes, x)

fn lct_make_root(mut nodes: InlineArray[Int64, NODE_FIELDS], x: Int):
    lct_access(mut nodes, x)
    lct_reverse(mut nodes, x)

fn lct_find_root(mut nodes: InlineArray[Int64, NODE_FIELDS], x: Int) -> Int:
    lct_access(mut nodes, x)
    lct_push(mut nodes, x)
    var root = x
    while nodes[field(0, root)] >= 0:
        root = Int(nodes[field(0, root)])
        lct_push(mut nodes, root)
    lct_splay(mut nodes, root)
    root

fn lct_link(mut nodes: InlineArray[Int64, NODE_FIELDS], u: Int, v: Int) -> Bool:
    if u == v: return False
    lct_make_root(mut nodes, u)
    if lct_find_root(mut nodes, v) == u: return False
    lct_access(mut nodes, v)
    nodes[field(2, u)] = v
    nodes[field(5, v)] += nodes[field(6, u)]
    lct_pull(mut nodes, v)
    True

fn lct_cut(mut nodes: InlineArray[Int64, NODE_FIELDS], u: Int, v: Int) -> Bool:
    if u == v: return False
    lct_make_root(mut nodes, u)
    lct_access(mut nodes, v)
    if nodes[field(0, v)] != u or nodes[field(1, u)] >= 0: return False
    nodes[field(0, v)] = -1
    nodes[field(2, u)] = -1
    lct_pull(mut nodes, v)
    True

fn lct_subtree_sum(mut nodes: InlineArray[Int64, NODE_FIELDS], vertex: Int, parent: Int) -> Int64:
    lct_make_root(mut nodes, parent)
    lct_access(mut nodes, vertex)
    if nodes[field(0, vertex)] != parent or nodes[field(1, parent)] >= 0: return -1
    nodes[field(4, vertex)] + nodes[field(5, vertex)]

fn store_i64(output: UnsafePointer[UInt8, MutAnyOrigin], offset: Int, value: Int64):
    let bits = bitcast[UInt64](value)
    for byte in range(8): output[offset + byte] = UInt8((bits >> (byte * 8)) & UInt64(255))

@export("dynamic_tree_vertex_add_subtree_sum")
fn dynamic_tree_vertex_add_subtree_sum(
    input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
    output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t,
) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 3 or length > c_size_t(MAX_INPUT): return -1
    let n_value = input[0]
    let q_value = input[1]
    if n_value < 1 or n_value > MAX_N or q_value < 0 or q_value > MAX_Q: return -1
    let n = Int(n_value)
    let q = Int(q_value)
    if length != c_size_t(3 * n + 5 * q): return -1
    for i in range(n):
        if input[2 + i] < 0 or input[2 + i] > MAX_VALUE: return -1
    let edge_start = 2 + n
    let operation_start = edge_start + 2 * (n - 1)
    for i in range(n - 1):
        let u = input[edge_start + 2 * i]
        let v = input[edge_start + 2 * i + 1]
        if u < 0 or u >= n_value or v < 0 or v >= n_value or u == v: return -1
    for i in range(q):
        let at = operation_start + 5 * i
        let kind = input[at]
        let a = input[at + 1]
        let b = input[at + 2]
        let c = input[at + 3]
        let d = input[at + 4]
        if kind == 0:
            if a < 0 or a >= n_value or b < 0 or b >= n_value or c < 0 or c >= n_value or d < 0 or d >= n_value or a == b or c == d: return -1
        elif kind == 1:
            if a < 0 or a >= n_value or b < 0 or b > MAX_VALUE or c != 0 or d != 0: return -1
        elif kind == 2:
            if a < 0 or a >= n_value or b < 0 or b >= n_value or c != 0 or d != 0: return -1
        else:
            return -1
    var nodes = InlineArray[Int64, NODE_FIELDS]()
    for i in range(MAX_N):
        nodes[field(0, i)] = -1
        nodes[field(1, i)] = -1
        nodes[field(2, i)] = -1
    for i in range(n):
        nodes[field(4, i)] = input[2 + i]
        nodes[field(6, i)] = input[2 + i]
    for i in range(n - 1):
        if not lct_link(mut nodes, Int(input[edge_start + 2 * i]), Int(input[edge_start + 2 * i + 1])): return -1
    var answers = InlineArray[Int64, MAX_Q]()
    var answer_count = 0
    for i in range(q):
        let at = operation_start + 5 * i
        let kind = Int(input[at])
        let a = Int(input[at + 1])
        let b = Int(input[at + 2])
        if kind == 0:
            let c = Int(input[at + 3])
            let d = Int(input[at + 4])
            if not lct_cut(mut nodes, a, b) or not lct_link(mut nodes, c, d): return -1
        elif kind == 1:
            lct_access(mut nodes, a)
            nodes[field(4, a)] += b
            lct_pull(mut nodes, a)
        else:
            let answer = lct_subtree_sum(mut nodes, a, b)
            if answer < 0: return -1
            answers[answer_count] = answer
            answer_count += 1
    let output_bytes = 8 * answer_count
    if output_bytes > 0 and (output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(output_bytes)): return -2
    for i in range(answer_count): store_i64(output, i * 8, answers[i])
    Int64(output_bytes)
