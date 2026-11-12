from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

alias MAX_N = 16
alias MAX_Q = 32
alias MAX_TOKENS = MAX_N + 2 * (MAX_N - 1 + MAX_Q)
alias NODE_FIELDS = 10 * MAX_TOKENS
alias TOTAL_FIELDS = NODE_FIELDS + 2
alias MAX_INPUT = 3 * MAX_N + 5 * MAX_Q + 1
alias MAX_DELTA = 1_000

fn field(slot: Int, node: Int) -> Int:
    slot * MAX_TOKENS + node

fn seq_size(nodes: InlineArray[Int64, TOTAL_FIELDS], id: Int) -> Int:
    if id < 0: return 0
    Int(nodes[field(4, id)])
fn marker_count(nodes: InlineArray[Int64, TOTAL_FIELDS], id: Int) -> Int:
    if id < 0: return 0
    Int(nodes[field(5, id)])
fn node_sum(nodes: InlineArray[Int64, TOTAL_FIELDS], id: Int) -> Int64:
    if id < 0: return 0
    nodes[field(8, id)]
fn pull(mut nodes: InlineArray[Int64, TOTAL_FIELDS], id: Int):
    nodes[field(4, id)] = 1 + seq_size(nodes, Int(nodes[field(0, id)])) + seq_size(nodes, Int(nodes[field(1, id)]))
    nodes[field(5, id)] = (if nodes[field(6, id)] != 0: 1 else: 0) + marker_count(nodes, Int(nodes[field(0, id)])) + marker_count(nodes, Int(nodes[field(1, id)]))
    nodes[field(8, id)] = nodes[field(7, id)] + node_sum(nodes, Int(nodes[field(0, id)])) + node_sum(nodes, Int(nodes[field(1, id)]))
fn apply_add(mut nodes: InlineArray[Int64, TOTAL_FIELDS], id: Int, delta: Int64):
    if id < 0 or marker_count(nodes, id) == 0: return
    nodes[field(8, id)] += delta * Int64(marker_count(nodes, id))
    if nodes[field(6, id)] != 0: nodes[field(7, id)] += delta
    nodes[field(9, id)] += delta
fn push(mut nodes: InlineArray[Int64, TOTAL_FIELDS], id: Int):
    let delta = nodes[field(9, id)]
    if delta == 0: return
    apply_add(mut nodes, Int(nodes[field(0, id)]), delta)
    apply_add(mut nodes, Int(nodes[field(1, id)]), delta)
    nodes[field(9, id)] = 0
fn next_priority(mut nodes: InlineArray[Int64, TOTAL_FIELDS]) -> Int64:
    var x = nodes[NODE_FIELDS + 1] & Int64(0xffffffff)
    x = (x ^ ((x << 13) & Int64(0xffffffff))) & Int64(0xffffffff)
    x = (x ^ (x >> 17)) & Int64(0xffffffff)
    x = (x ^ ((x << 5) & Int64(0xffffffff))) & Int64(0xffffffff)
    nodes[NODE_FIELDS + 1] = x
    x
fn new_node(mut nodes: InlineArray[Int64, TOTAL_FIELDS], marker: Bool, value: Int64) -> Int:
    let id = Int(nodes[NODE_FIELDS])
    if id >= MAX_TOKENS: return -1
    nodes[NODE_FIELDS] += 1
    nodes[field(0, id)] = -1
    nodes[field(1, id)] = -1
    nodes[field(2, id)] = -1
    nodes[field(3, id)] = next_priority(mut nodes)
    nodes[field(4, id)] = 1
    nodes[field(5, id)] = if marker: 1 else: 0
    nodes[field(6, id)] = if marker: 1 else: 0
    nodes[field(7, id)] = if marker: value else: 0
    nodes[field(8, id)] = if marker: value else: 0
    nodes[field(9, id)] = 0
    id
fn split(mut nodes: InlineArray[Int64, TOTAL_FIELDS], root: Int, count: Int) -> InlineArray[Int, 2]:
    var result = InlineArray[Int, 2]()
    if root < 0:
        result[0] = -1; result[1] = -1
        return result
    push(mut nodes, root)
    nodes[field(2, root)] = -1
    let left = Int(nodes[field(0, root)])
    if seq_size(nodes, left) >= count:
        let parts = split(mut nodes, left, count)
        nodes[field(0, root)] = parts[1]
        if parts[1] >= 0: nodes[field(2, parts[1])] = root
        pull(mut nodes, root)
        result[0] = parts[0]; result[1] = root
        return result
    let right = Int(nodes[field(1, root)])
    let parts = split(mut nodes, right, count - seq_size(nodes, left) - 1)
    nodes[field(1, root)] = parts[0]
    if parts[0] >= 0: nodes[field(2, parts[0])] = root
    pull(mut nodes, root)
    result[0] = root; result[1] = parts[1]
    result
fn merge(mut nodes: InlineArray[Int64, TOTAL_FIELDS], first: Int, second: Int) -> Int:
    if first < 0:
        if second >= 0: nodes[field(2, second)] = -1
        return second
    if second < 0:
        nodes[field(2, first)] = -1
        return first
    nodes[field(2, first)] = -1; nodes[field(2, second)] = -1
    if nodes[field(3, first)] >= nodes[field(3, second)]:
        push(mut nodes, first)
        let joined = merge(mut nodes, Int(nodes[field(1, first)]), second)
        nodes[field(1, first)] = joined
        if joined >= 0: nodes[field(2, joined)] = first
        pull(mut nodes, first)
        return first
    push(mut nodes, second)
    let joined = merge(mut nodes, first, Int(nodes[field(0, second)]))
    nodes[field(0, second)] = joined
    if joined >= 0: nodes[field(2, joined)] = second
    pull(mut nodes, second)
    second
fn root_of(nodes: InlineArray[Int64, TOTAL_FIELDS], start: Int) -> Int:
    var id = start
    while nodes[field(2, id)] >= 0: id = Int(nodes[field(2, id)])
    id
fn rank_of(nodes: InlineArray[Int64, TOTAL_FIELDS], start: Int) -> Int:
    var id = start
    var rank = seq_size(nodes, Int(nodes[field(0, id)]))
    while nodes[field(2, id)] >= 0:
        let parent = Int(nodes[field(2, id)])
        if nodes[field(1, parent)] == id: rank += 1 + seq_size(nodes, Int(nodes[field(0, parent)]))
        id = parent
    rank
fn rotate_to(mut nodes: InlineArray[Int64, TOTAL_FIELDS], id: Int) -> Int:
    let parts = split(mut nodes, root_of(nodes, id), rank_of(nodes, id))
    merge(mut nodes, parts[1], parts[0])
fn link_tours(mut nodes: InlineArray[Int64, TOTAL_FIELDS], markers: InlineArray[Int, MAX_N], u: Int, v: Int) -> InlineArray[Int, 2]:
    var result = InlineArray[Int, 2]()
    let root_u = root_of(nodes, markers[u]); let root_v = root_of(nodes, markers[v])
    if root_u == root_v: result[0] = -1; result[1] = -1; return result
    let a = split(mut nodes, root_u, rank_of(nodes, markers[u]) + 1)
    let b = split(mut nodes, root_v, rank_of(nodes, markers[v]))
    let b2 = split(mut nodes, b[1], 1)
    let uv = new_node(mut nodes, False, 0); let vu = new_node(mut nodes, False, 0)
    if uv < 0 or vu < 0: result[0] = -1; result[1] = -1; return result
    var root = merge(mut nodes, a[0], uv)
    root = merge(mut nodes, root, b2[1]); root = merge(mut nodes, root, b[0])
    root = merge(mut nodes, root, b2[0]); root = merge(mut nodes, root, vu)
    _ = merge(mut nodes, root, a[1])
    result[0] = uv; result[1] = vu
    result
fn cut_tours(mut nodes: InlineArray[Int64, TOTAL_FIELDS], uv: Int, vu: Int) -> Bool:
    let root = rotate_to(mut nodes, uv)
    let reverse_rank = rank_of(nodes, vu)
    if reverse_rank == 0: return False
    let a = split(mut nodes, root, 1)
    let b = split(mut nodes, a[1], reverse_rank - 1)
    let c = split(mut nodes, b[1], 1)
    if a[0] != uv or c[0] != vu: return False
    nodes[field(0, uv)] = -1; nodes[field(1, uv)] = -1; nodes[field(2, uv)] = -1
    nodes[field(0, vu)] = -1; nodes[field(1, vu)] = -1; nodes[field(2, vu)] = -1
    True
fn side_operation(mut nodes: InlineArray[Int64, TOTAL_FIELDS], uv: Int, vu: Int, update: Bool, delta: Int64) -> InlineArray[Int64, 2]:
    var result = InlineArray[Int64, 2]()
    let root = rotate_to(mut nodes, uv)
    let reverse_rank = rank_of(nodes, vu)
    if reverse_rank == 0: result[0] = 0; result[1] = 0; return result
    let a = split(mut nodes, root, 1)
    let b = split(mut nodes, a[1], reverse_rank - 1)
    if a[0] != uv or b[0] < 0: result[0] = 0; result[1] = 0; return result
    if update: apply_add(mut nodes, b[0], delta)
    else: result[1] = node_sum(nodes, b[0])
    let joined = merge(mut nodes, a[0], b[0]); _ = merge(mut nodes, joined, b[1])
    result[0] = 1
    result

fn connected(adjacency: InlineArray[Bool, MAX_N * MAX_N], n: Int, start: Int, goal: Int) -> Bool:
    var seen = InlineArray[Bool, MAX_N]()
    var queue = InlineArray[Int, MAX_N]()
    var head = 0; var tail = 1
    queue[0] = start; seen[start] = True
    while head < tail:
        let u = queue[head]; head += 1
        if u == goal: return True
        for v in range(n):
            if adjacency[u * MAX_N + v] and not seen[v]: seen[v] = True; queue[tail] = v; tail += 1
    False
fn validate_fields(input: UnsafePointer[Int64, ImmutAnyOrigin], n: Int, q: Int) -> InlineArray[Int, 2]:
    var result = InlineArray[Int, 2]()
    for i in range(n):
        if input[2 + i] < 0 or input[2 + i] > MAX_DELTA: result[0] = 0; return result
    let edge_start = 2 + n
    for i in range(n - 1):
        let u = input[edge_start + 2 * i]; let v = input[edge_start + 2 * i + 1]
        if u < 0 or u >= n or v < 0 or v >= n or u == v: result[0] = 0; return result
    let operations = edge_start + 2 * (n - 1)
    for i in range(q):
        let at = operations + 5 * i
        let kind = input[at]; let v = input[at + 1]; let p = input[at + 2]; let a = input[at + 3]; let b = input[at + 4]
        if kind == 0:
            if v < 0 or v >= n or p < 0 or p >= n or a < 0 or a >= n or b < 0 or b >= n or v == p or a == b: result[0] = 0; return result
        elif kind == 1:
            if v < 0 or v >= n or p < 0 or p >= n or v == p or a < 0 or a > MAX_DELTA or b != 0: result[0] = 0; return result
        elif kind == 2:
            if v < 0 or v >= n or p < 0 or p >= n or v == p or a != 0 or b != 0: result[0] = 0; return result
            result[1] += 1
        else: result[0] = 0; return result
    result[0] = 1
    result
fn validate_topology(input: UnsafePointer[Int64, ImmutAnyOrigin], n: Int, q: Int) -> Bool:
    var adjacency = InlineArray[Bool, MAX_N * MAX_N]()
    let edge_start = 2 + n; let operations = edge_start + 2 * (n - 1)
    for i in range(n - 1):
        let u = Int(input[edge_start + 2 * i]); let v = Int(input[edge_start + 2 * i + 1])
        if adjacency[u * MAX_N + v]: return False
        adjacency[u * MAX_N + v] = True; adjacency[v * MAX_N + u] = True
    for v in range(n):
        if not connected(adjacency, n, 0, v): return False
    for i in range(q):
        let at = operations + 5 * i; let kind = Int(input[at]); let v = Int(input[at + 1]); let p = Int(input[at + 2])
        if kind == 0:
            let a = Int(input[at + 3]); let b = Int(input[at + 4])
            if not adjacency[v * MAX_N + p]: return False
            adjacency[v * MAX_N + p] = False; adjacency[p * MAX_N + v] = False
            if connected(adjacency, n, a, b): return False
            adjacency[a * MAX_N + b] = True; adjacency[b * MAX_N + a] = True
        elif not adjacency[v * MAX_N + p]: return False
    True
fn store_i64(output: UnsafePointer[UInt8, MutAnyOrigin], offset: Int, value: Int64):
    let bits = bitcast[UInt64](value)
    for byte in range(8): output[offset + byte] = UInt8((bits >> (byte * 8)) & UInt64(255))

@export("dynamic_tree_subtree_add_subtree_sum")
fn dynamic_tree_subtree_add_subtree_sum(
    input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
    output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t,
) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 2 or length > c_size_t(MAX_INPUT): return -1
    let n_value = input[0]; let q_value = input[1]
    if n_value < 1 or n_value > MAX_N or q_value < 0 or q_value > MAX_Q: return -1
    let n = Int(n_value); let q = Int(q_value)
    if length != c_size_t(3 * n + 5 * q): return -1
    let fields = validate_fields(input, n, q)
    if fields[0] == 0 or not validate_topology(input, n, q): return -1
    let output_bytes = 8 * fields[1]
    if output_bytes > 0 and (output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(output_bytes)): return -2
    var nodes = InlineArray[Int64, TOTAL_FIELDS]()
    nodes[NODE_FIELDS + 1] = Int64(0x9e3779b9)
    var markers = InlineArray[Int, MAX_N]()
    for i in range(n): markers[i] = new_node(mut nodes, True, input[2 + i])
    var directed = InlineArray[Int, MAX_N * MAX_N]()
    for i in range(MAX_N * MAX_N): directed[i] = -1
    let edge_start = 2 + n; let operations = edge_start + 2 * (n - 1)
    for i in range(n - 1):
        let u = Int(input[edge_start + 2 * i]); let v = Int(input[edge_start + 2 * i + 1])
        let edge = link_tours(mut nodes, markers, u, v)
        if edge[0] < 0: return -1
        directed[u * MAX_N + v] = edge[0]; directed[v * MAX_N + u] = edge[1]
    var answers = InlineArray[Int64, MAX_Q]()
    var answer_count = 0
    for i in range(q):
        let at = operations + 5 * i; let kind = Int(input[at]); let v = Int(input[at + 1]); let p = Int(input[at + 2])
        if kind == 0:
            let a = Int(input[at + 3]); let b = Int(input[at + 4]); let uv = directed[v * MAX_N + p]; let vu = directed[p * MAX_N + v]
            if uv < 0 or vu < 0 or not cut_tours(mut nodes, uv, vu): return -1
            directed[v * MAX_N + p] = -1; directed[p * MAX_N + v] = -1
            let edge = link_tours(mut nodes, markers, a, b)
            if edge[0] < 0: return -1
            directed[a * MAX_N + b] = edge[0]; directed[b * MAX_N + a] = edge[1]
        elif kind == 1:
            let outcome = side_operation(mut nodes, directed[p * MAX_N + v], directed[v * MAX_N + p], True, input[at + 3])
            if outcome[0] == 0: return -1
        else:
            let outcome = side_operation(mut nodes, directed[p * MAX_N + v], directed[v * MAX_N + p], False, 0)
            if outcome[0] == 0: return -1
            answers[answer_count] = outcome[1]; answer_count += 1
    if output_bytes > 0:
        for i in range(answer_count): store_i64(output, i * 8, answers[i])
    Int64(output_bytes)
