from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
from std.collections import List

comptime MAX_N = 8
comptime MAX_EDGES = 28
comptime WALK_LIMIT = 64
comptime MAX_INPUT = 4 + 2 * MAX_EDGES + WALK_LIMIT * (MAX_N - 1)

@export("wilson_uniform_spanning_tree")
fn wilson_uniform_spanning_tree(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
        output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 4 or length > MAX_INPUT + 1: return -1
    let n_raw = input[0]
    let m_raw = input[1]
    let root_raw = input[2]
    if n_raw < 1 or n_raw > MAX_N or m_raw < 0 or m_raw > MAX_EDGES: return -1
    let n = Int(n_raw)
    let m = Int(m_raw)
    if root_raw < 0 or root_raw >= n_raw: return -1
    let root = Int(root_raw)
    let q_at = 3 + 2 * m
    if length <= c_size_t(q_at): return -1
    let q_raw = input[q_at]
    if q_raw < 0 or q_raw > WALK_LIMIT * (n - 1): return -1
    let q = Int(q_raw)
    if length != c_size_t(q_at + 1 + q): return -1

    var neighbors = List[Int](capacity=MAX_N * (MAX_N - 1))
    var degree = List[Int](capacity=MAX_N)
    for _ in range(MAX_N * (MAX_N - 1)): neighbors.append(0)
    for _ in range(MAX_N): degree.append(0)
    var previous_u = -1
    var previous_v = -1
    for edge in range(m):
        let u_raw = input[3 + 2 * edge]
        let v_raw = input[4 + 2 * edge]
        if u_raw < 0 or u_raw >= v_raw or v_raw >= n_raw: return -1
        if edge > 0 and (u_raw < previous_u or (u_raw == previous_u and v_raw <= previous_v)): return -1
        previous_u = Int(u_raw)
        previous_v = Int(v_raw)
        let u = Int(u_raw)
        let v = Int(v_raw)
        neighbors[u * (MAX_N - 1) + degree[u]] = v
        degree[u] += 1
        neighbors[v * (MAX_N - 1) + degree[v]] = u
        degree[v] += 1
    for draw in range(q):
        let value = input[q_at + 1 + draw]
        if value < 0 or value > MAX_N - 2: return -1

    var seen = List[Bool](capacity=MAX_N)
    var queue = List[Int](capacity=MAX_N)
    for _ in range(MAX_N):
        seen.append(False)
        queue.append(0)
    var head = 0
    var tail = 0
    seen[root] = True
    queue[tail] = root
    tail += 1
    while head < tail:
        let at = queue[head]
        head += 1
        for k in range(degree[at]):
            let to = neighbors[at * (MAX_N - 1) + k]
            if not seen[to]:
                seen[to] = True
                queue[tail] = to
                tail += 1
    for vertex in range(n):
        if not seen[vertex]: return -1

    var in_tree = List[Bool](capacity=MAX_N)
    var successor = List[Int](capacity=MAX_N)
    for _ in range(MAX_N):
        in_tree.append(False)
        successor.append(-1)
    in_tree[root] = True
    var cursor = 0
    for start in range(n):
        if in_tree[start]: continue
        var current = start
        var steps = 0
        while not in_tree[current]:
            if steps >= WALK_LIMIT or cursor >= q: return -1
            let choice = Int(input[q_at + 1 + cursor])
            if choice >= degree[current]: return -1
            successor[current] = neighbors[current * (MAX_N - 1) + choice]
            current = successor[current]
            cursor += 1
            steps += 1
        current = start
        while not in_tree[current]:
            in_tree[current] = True
            current = successor[current]
    if cursor != q: return -1

    let required = 16 * (n - 1)
    if (required > 0 and output == UnsafePointer[UInt8, MutAnyOrigin]()) or capacity < c_size_t(required): return -2
    var offset = 0
    for child in range(n):
        if child == root: continue
        let parent = successor[child]
        let child_bits = UInt64(child)
        let parent_bits = UInt64(parent)
        for byte in range(8):
            output.add(offset + byte).write(UInt8((child_bits >> (8 * byte)) & 255))
            output.add(offset + 8 + byte).write(UInt8((parent_bits >> (8 * byte)) & 255))
        offset += 16
    Int64(required)
