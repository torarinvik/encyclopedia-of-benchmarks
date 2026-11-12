from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

comptime ETT_N = 8
comptime ETT_M = 32
comptime ETT_NODES = ETT_N + 2 * ETT_M
comptime ETT_INPUT_MAX = 2 + ETT_N + 3 * ETT_M

struct EttOp:
    kind: Int64
    a: Int64
    b: Int64

struct EttTree:
    left: InlineArray[Int, ETT_NODES]
    right: InlineArray[Int, ETT_NODES]
    parent: InlineArray[Int, ETT_NODES]
    vertex: InlineArray[Int, ETT_NODES]
    size: InlineArray[Int, ETT_NODES]
    count: InlineArray[Int, ETT_NODES]
    value: InlineArray[Int64, ETT_NODES]
    total: InlineArray[Int64, ETT_NODES]
    priority: InlineArray[Int64, ETT_NODES]
    edge_u: InlineArray[Int, ETT_M]
    edge_v: InlineArray[Int, ETT_M]
    arc_uv: InlineArray[Int, ETT_M]
    arc_vu: InlineArray[Int, ETT_M]
    active: InlineArray[Bool, ETT_M]
    next_node: Int
    edge_count: Int

fn ett_size(tree: EttTree, node: Int) -> Int:
    return 0 if node < 0 else tree.size[node]

fn ett_count(tree: EttTree, node: Int) -> Int:
    return 0 if node < 0 else tree.count[node]

fn ett_total(tree: EttTree, node: Int) -> Int64:
    return 0 if node < 0 else tree.total[node]

fn ett_pull(mut tree: EttTree, node: Int):
    if node < 0: return
    tree.size[node] = 1 + ett_size(tree, tree.left[node]) + ett_size(tree, tree.right[node])
    tree.count[node] = (1 if tree.vertex[node] >= 0 else 0) + ett_count(tree, tree.left[node]) + ett_count(tree, tree.right[node])
    tree.total[node] = tree.value[node] + ett_total(tree, tree.left[node]) + ett_total(tree, tree.right[node])

fn ett_merge(mut tree: EttTree, a: Int, b: Int) -> Int:
    if a < 0:
        if b >= 0: tree.parent[b] = -1
        return b
    if b < 0:
        tree.parent[a] = -1
        return a
    if tree.priority[a] > tree.priority[b]:
        let child = ett_merge(mut tree, tree.right[a], b)
        tree.right[a] = child
        if child >= 0: tree.parent[child] = a
        ett_pull(mut tree, a)
        tree.parent[a] = -1
        return a
    let child = ett_merge(mut tree, a, tree.left[b])
    tree.left[b] = child
    if child >= 0: tree.parent[child] = b
    ett_pull(mut tree, b)
    tree.parent[b] = -1
    return b

fn ett_split(mut tree: EttTree, root: Int, prefix: Int) -> (Int, Int):
    if root < 0: return (-1, -1)
    if prefix <= ett_size(tree, tree.left[root]):
        let (first, rest) = ett_split(mut tree, tree.left[root], prefix)
        tree.left[root] = rest
        if rest >= 0: tree.parent[rest] = root
        ett_pull(mut tree, root)
        tree.parent[root] = -1
        if first >= 0: tree.parent[first] = -1
        return (first, root)
    let left_size = ett_size(tree, tree.left[root])
    let (first, rest) = ett_split(mut tree, tree.right[root], prefix - left_size - 1)
    tree.right[root] = first
    if first >= 0: tree.parent[first] = root
    ett_pull(mut tree, root)
    tree.parent[root] = -1
    if rest >= 0: tree.parent[rest] = -1
    return (root, rest)

fn ett_root(tree: EttTree, node: Int) -> Int:
    var current = node
    while tree.parent[current] >= 0: current = tree.parent[current]
    return current

fn ett_position(tree: EttTree, node: Int) -> Int:
    var current = node
    var result = ett_size(tree, tree.left[current])
    while tree.parent[current] >= 0:
        let parent = tree.parent[current]
        if tree.right[parent] == current: result += 1 + ett_size(tree, tree.left[parent])
        current = parent
    return result

fn ett_rotate(mut tree: EttTree, root: Int, node: Int) -> Int:
    let node_position = ett_position(tree, node)
    let (first, rest) = ett_split(mut tree, root, node_position)
    return ett_merge(mut tree, rest, first)

fn ett_reachable(adjacency: InlineArray[Bool, ETT_N * ETT_N], start: Int, target: Int, n: Int) -> Bool:
    var seen = InlineArray[Bool, ETT_N](fill=False)
    var stack = InlineArray[Int, ETT_N](fill=0)
    var top = 0
    stack[top] = start
    top += 1
    seen[start] = True
    while top > 0:
        top -= 1
        let vertex = stack[top]
        if vertex == target: return True
        for neighbor in range(n):
            if adjacency[vertex * ETT_N + neighbor] and not seen[neighbor]:
                seen[neighbor] = True
                stack[top] = neighbor
                top += 1
    return False

fn ett_init(mut tree: EttTree, weights: InlineArray[Int64, ETT_N], n: Int):
    for i in range(ETT_NODES):
        tree.left[i] = -1
        tree.right[i] = -1
        tree.parent[i] = -1
        tree.vertex[i] = -1
        tree.size[i] = 0
        tree.count[i] = 0
        tree.value[i] = 0
        tree.total[i] = 0
        tree.priority[i] = (i * 40503 + 17) % 65521
    for i in range(n):
        tree.vertex[i] = i
        tree.size[i] = 1
        tree.count[i] = 1
        tree.value[i] = weights[i]
        tree.total[i] = weights[i]
    tree.next_node = n
    tree.edge_count = 0

fn ett_link(mut tree: EttTree, u: Int, v: Int):
    let root_a = ett_root(tree, u)
    let a = ett_rotate(mut tree, root_a, u)
    let root_b = ett_root(tree, v)
    let b = ett_rotate(mut tree, root_b, v)
    let uv = tree.next_node
    let vu = uv + 1
    tree.next_node += 2
    for x in range(2):
        let node = uv if x == 0 else vu
        tree.left[node] = -1
        tree.right[node] = -1
        tree.parent[node] = -1
        tree.vertex[node] = -1
        tree.size[node] = 1
        tree.count[node] = 0
        tree.value[node] = 0
        tree.total[node] = 0
    let first_join = ett_merge(mut tree, a, uv)
    let second_join = ett_merge(mut tree, first_join, b)
    let root = ett_merge(mut tree, second_join, vu)
    tree.parent[root] = -1
    let edge = tree.edge_count
    tree.edge_count += 1
    tree.edge_u[edge] = u
    tree.edge_v[edge] = v
    tree.arc_uv[edge] = uv
    tree.arc_vu[edge] = vu
    tree.active[edge] = True

fn ett_cut(mut tree: EttTree, u: Int, v: Int):
    var edge = -1
    for offset in range(tree.edge_count):
        let i = tree.edge_count - offset - 1
        if tree.active[i] and ((tree.edge_u[i] == u and tree.edge_v[i] == v) or (tree.edge_u[i] == v and tree.edge_v[i] == u)):
            edge = i
            break
    let first_arc = tree.arc_uv[edge] if tree.edge_u[edge] == u and tree.edge_v[edge] == v else tree.arc_vu[edge]
    let second_arc = tree.arc_vu[edge] if first_arc == tree.arc_uv[edge] else tree.arc_uv[edge]
    let starting_root = ett_root(tree, first_arc)
    let root = ett_rotate(mut tree, starting_root, first_arc)
    let (_, rest) = ett_split(mut tree, root, 1)
    let second_position = ett_position(tree, second_arc)
    let (between, suffix) = ett_split(mut tree, rest, second_position)
    let (_, other) = ett_split(mut tree, suffix, 1)
    if between >= 0: tree.parent[between] = -1
    if other >= 0: tree.parent[other] = -1
    tree.active[edge] = False

fn ett_set_weight(mut tree: EttTree, vertex: Int, value: Int64):
    tree.value[vertex] = value
    var path = InlineArray[Int, ETT_NODES](fill=0)
    var count = 0
    var node = vertex
    while node >= 0:
        path[count] = node
        count += 1
        node = tree.parent[node]
    for i in range(count):
        ett_pull(mut tree, path[i])

fn ett_store(output: UnsafePointer[UInt8, MutAnyOrigin], offset: Int, value: Int64):
    let bits = bitcast[UInt64](value)
    for byte in range(8): output[offset + byte] = UInt8((bits >> UInt(8 * byte)) & 255)

@export("euler_tour_tree")
fn euler_tour_tree(
    input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
    output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t,
) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 2 or length > ETT_INPUT_MAX: return -1
    let nr = input[0]
    let mr = input[1]
    if nr < 1 or nr > ETT_N or mr < 1 or mr > ETT_M: return -1
    let n = Int(nr)
    let m = Int(mr)
    var cursor = 2
    var weights = InlineArray[Int64, ETT_N](fill=0)
    for i in range(n):
        if cursor >= Int(length): return -1
        weights[i] = input[cursor]
        cursor += 1
        if weights[i] < -100 or weights[i] > 100: return -1
    var operations = InlineArray[EttOp, ETT_M](fill=EttOp(0, 0, 0))
    var query_count = 0
    for i in range(m):
        if cursor >= Int(length): return -1
        let kind = input[cursor]
        cursor += 1
        if kind == 0 or kind == 1:
            if cursor + 2 > Int(length): return -1
            let u = input[cursor]
            let v = input[cursor + 1]
            cursor += 2
            if u < 0 or u >= nr or v < 0 or v >= nr or u == v: return -1
            operations[i] = EttOp(kind, u, v)
        elif kind == 2:
            if cursor + 2 > Int(length): return -1
            let vertex = input[cursor]
            let value = input[cursor + 1]
            cursor += 2
            if vertex < 0 or vertex >= nr or value < -100 or value > 100: return -1
            operations[i] = EttOp(kind, vertex, value)
        elif kind == 3:
            if cursor >= Int(length): return -1
            let vertex = input[cursor]
            cursor += 1
            if vertex < 0 or vertex >= nr: return -1
            operations[i] = EttOp(kind, vertex, 0)
            query_count += 1
        else: return -1
    if cursor != Int(length) or query_count == 0: return -1
    var adjacency = InlineArray[Bool, ETT_N * ETT_N](fill=False)
    for i in range(m):
        let op = operations[i]
        let u = Int(op.a)
        let v = Int(op.b)
        if op.kind == 0:
            if ett_reachable(adjacency, u, v, n): return -1
            adjacency[u * ETT_N + v] = True
            adjacency[v * ETT_N + u] = True
        elif op.kind == 1:
            if not adjacency[u * ETT_N + v]: return -1
            adjacency[u * ETT_N + v] = False
            adjacency[v * ETT_N + u] = False
    let required = 16 * query_count
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(required): return -2
    var tree = EttTree(
        InlineArray[Int, ETT_NODES](fill=-1), InlineArray[Int, ETT_NODES](fill=-1),
        InlineArray[Int, ETT_NODES](fill=-1), InlineArray[Int, ETT_NODES](fill=-1),
        InlineArray[Int, ETT_NODES](fill=0), InlineArray[Int, ETT_NODES](fill=0),
        InlineArray[Int64, ETT_NODES](fill=0), InlineArray[Int64, ETT_NODES](fill=0),
        InlineArray[Int64, ETT_NODES](fill=0), InlineArray[Int, ETT_M](fill=0),
        InlineArray[Int, ETT_M](fill=0), InlineArray[Int, ETT_M](fill=0),
        InlineArray[Int, ETT_M](fill=0), InlineArray[Bool, ETT_M](fill=False), 0, 0)
    ett_init(mut tree, weights, n)
    var answers = InlineArray[Int64, 2 * ETT_M](fill=0)
    var answer_count = 0
    for i in range(m):
        let op = operations[i]
        let a = Int(op.a)
        let b = Int(op.b)
        if op.kind == 0: ett_link(mut tree, a, b)
        elif op.kind == 1: ett_cut(mut tree, a, b)
        elif op.kind == 2: ett_set_weight(mut tree, a, op.b)
        else:
            let root = ett_root(tree, a)
            answers[answer_count] = Int64(tree.count[root])
            answers[answer_count + 1] = tree.total[root]
            answer_count += 2
    for i in range(answer_count): ett_store(output, 8 * i, answers[i])
    return Int64(required)
