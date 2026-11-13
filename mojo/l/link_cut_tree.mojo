from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

struct LinkCutNode(Copyable):
    var left: Int = -1
    var right: Int = -1
    var parent: Int = -1
    var reversed: Bool = False
    var value: Int64 = 0
    var sum: Int64 = 0

fn lct_root(nodes: InlineArray[LinkCutNode, 16], x: Int) -> Bool:
    # A represented-tree path parent does not make x a splay child.
    let p = nodes[x].parent
    return p < 0 or (nodes[p].left != x and nodes[p].right != x)

fn lct_pull(mut nodes: InlineArray[LinkCutNode, 16], x: Int):
    var sum = nodes[x].value
    if nodes[x].left >= 0: sum += nodes[nodes[x].left].sum
    if nodes[x].right >= 0: sum += nodes[nodes[x].right].sum
    nodes[x].sum = sum

fn lct_reverse(mut nodes: InlineArray[LinkCutNode, 16], x: Int):
    if x < 0: return
    let left = nodes[x].left
    nodes[x].left = nodes[x].right
    nodes[x].right = left
    nodes[x].reversed = not nodes[x].reversed

fn lct_push(mut nodes: InlineArray[LinkCutNode, 16], x: Int):
    if not nodes[x].reversed: return
    let left = nodes[x].left
    let right = nodes[x].right
    lct_reverse(mut nodes, left)
    lct_reverse(mut nodes, right)
    nodes[x].reversed = False

fn lct_rotate(mut nodes: InlineArray[LinkCutNode, 16], x: Int):
    let p = nodes[x].parent
    let g = nodes[p].parent
    let right = nodes[p].right == x
    var middle = nodes[x].right
    if right: middle = nodes[x].left
    if not lct_root(nodes, p):
        if nodes[g].right == p: nodes[g].right = x
        else: nodes[g].left = x
    nodes[x].parent = g
    nodes[p].parent = x
    if right:
        nodes[x].left = p
        nodes[p].right = middle
    else:
        nodes[x].right = p
        nodes[p].left = middle
    if middle >= 0: nodes[middle].parent = p
    lct_pull(mut nodes, p)
    lct_pull(mut nodes, x)

fn lct_splay(mut nodes: InlineArray[LinkCutNode, 16], x: Int):
    var stack = InlineArray[Int, 16](fill=0)
    var count = 1
    var y = x
    stack[0] = y
    while not lct_root(nodes, y):
        y = nodes[y].parent
        stack[count] = y
        count += 1
    while count > 0:
        count -= 1
        lct_push(mut nodes, stack[count])
    while not lct_root(nodes, x):
        let p = nodes[x].parent
        if not lct_root(nodes, p):
            let g = nodes[p].parent
            if (nodes[p].left == x) == (nodes[g].left == p): lct_rotate(mut nodes, p)
            else: lct_rotate(mut nodes, x)
        lct_rotate(mut nodes, x)

fn lct_access(mut nodes: InlineArray[LinkCutNode, 16], x: Int):
    # Rebuild the preferred path while preserving detached path-parent links.
    var last = -1
    var y = x
    while y >= 0:
        lct_splay(mut nodes, y)
        nodes[y].right = last
        if last >= 0: nodes[last].parent = y
        lct_pull(mut nodes, y)
        last = y
        y = nodes[y].parent
    lct_splay(mut nodes, x)

fn lct_make_root(mut nodes: InlineArray[LinkCutNode, 16], x: Int):
    lct_access(mut nodes, x)
    lct_reverse(mut nodes, x)

fn lct_find_root(mut nodes: InlineArray[LinkCutNode, 16], x: Int) -> Int:
    lct_access(mut nodes, x)
    var current = x
    lct_push(mut nodes, current)
    while nodes[current].left >= 0:
        current = nodes[current].left
        lct_push(mut nodes, current)
    lct_splay(mut nodes, current)
    return current

@export("link_cut_tree")
fn link_cut_tree(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
                 output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 2 or length > 210: return -1
    let n64 = input[0]
    let q64 = input[1]
    if n64 < 1 or n64 > 16 or q64 < 1 or q64 > 64: return -1
    let n = Int(n64)
    let q = Int(q64)
    if length != c_size_t(2 + n + 3 * q): return -1
    for vertex in range(n):
        if input[2 + vertex] < 0 or input[2 + vertex] > 1000000: return -1
    for i in range(q):
        let at = 2 + n + 3 * i
        if input[at] < 0 or input[at] > 2 or input[at + 1] < 0 or input[at + 1] >= n64 or input[at + 2] < 0 or input[at + 2] >= n64: return -1
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(8 * q): return -2
    var nodes = InlineArray[LinkCutNode, 16](fill=LinkCutNode())
    for vertex in range(n):
        nodes[vertex].value = input[2 + vertex]
        nodes[vertex].sum = input[2 + vertex]
    for i in range(q):
        let at = 2 + n + 3 * i
        let op = input[at]
        let u = Int(input[at + 1])
        let v = Int(input[at + 2])
        var result: Int64 = 0
        if op == 0:
            if u != v:
                lct_make_root(mut nodes, u)
                if lct_find_root(mut nodes, v) != u:
                    nodes[u].parent = v
                    result = 1
        elif op == 1:
            if u != v:
                lct_make_root(mut nodes, u)
                lct_access(mut nodes, v)
                if nodes[v].left == u and nodes[u].right < 0:
                    nodes[v].left = -1
                    nodes[u].parent = -1
                    lct_pull(mut nodes, v)
                    result = 1
        else:
            lct_make_root(mut nodes, u)
            if lct_find_root(mut nodes, v) != u:
                result = -1
            else:
                lct_make_root(mut nodes, u)
                lct_access(mut nodes, v)
                result = nodes[v].sum
        var bits = UInt64(0xffffffffffffffff)
        if result >= 0: bits = UInt64(result)
        for byte in range(8): output[8 * i + byte] = UInt8((bits >> UInt(8 * byte)) & 255)
    return Int64(8 * q)
