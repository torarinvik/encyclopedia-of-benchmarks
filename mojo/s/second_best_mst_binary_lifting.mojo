from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

fn mst_lifting_merge(a: Int64, b: Int64, c: Int64, d: Int64) -> Tuple[Int64, Int64]:
    var first: Int64 = -1
    var second: Int64 = -1
    var values = InlineArray[Int64, 4](a, b, c, d)
    for i in range(4):
        let value = values[i]
        if value > first:
            second = first
            first = value
        elif value < first and value > second:
            second = value
    return (first, second)

@export("second_best_mst_binary_lifting")
fn second_best_mst_binary_lifting(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 2 or length > 63: return -1
    let nv = input[0]
    let mv = input[1]
    if nv < 1 or nv > 8 or mv < nv - 1 or mv > 20 or length != c_size_t(2 + 3 * mv): return -1
    let n = Int(nv)
    let m = Int(mv)
    var u = InlineArray[Int, 20]()
    var v = InlineArray[Int, 20]()
    var weight = InlineArray[Int64, 20]()
    var order = InlineArray[Int, 20]()
    var seen = InlineArray[Bool, 64](fill=False)
    for i in range(m):
        let a = input[2 + 3 * i]
        let b = input[3 + 3 * i]
        let w = input[4 + 3 * i]
        if a < 0 or a >= b or b >= nv or w < 0 or w > 1000000: return -1
        let pos = Int(a * 8 + b)
        if seen[pos]: return -1
        seen[pos] = True
        u[i] = Int(a)
        v[i] = Int(b)
        weight[i] = w
        order[i] = i
    for i in range(1, m):
        let edge = order[i]
        var j = i
        while j > 0 and weight[order[j - 1]] > weight[edge]:
            order[j] = order[j - 1]
            j -= 1
        order[j] = edge
    var parent = InlineArray[Int, 8]()
    var degree = InlineArray[Int, 8](fill=0)
    var adjacent = InlineArray[Int, 64]()
    var edge_at = InlineArray[Int, 64]()
    var selected = InlineArray[Bool, 20](fill=False)
    for i in range(n): parent[i] = i
    var count = 0
    var total: Int64 = 0
    for i in range(m):
        let edge = order[i]
        var a = u[edge]
        var b = v[edge]
        while parent[a] != a: a = parent[a]
        while parent[b] != b: b = parent[b]
        if a == b: continue
        parent[a] = b
        selected[edge] = True
        count += 1
        total += weight[edge]
        let pu = u[edge] * 8 + degree[u[edge]]
        let pv = v[edge] * 8 + degree[v[edge]]
        adjacent[pu] = v[edge]
        adjacent[pv] = u[edge]
        edge_at[pu] = edge
        edge_at[pv] = edge
        degree[u[edge]] += 1
        degree[v[edge]] += 1
    if count != n - 1: return -1
    var up = InlineArray[Int, 32](fill=0)
    var first = InlineArray[Int64, 32]()
    var second = InlineArray[Int64, 32]()
    var depth = InlineArray[Int, 8]()
    var queue = InlineArray[Int, 8]()
    for i in range(32):
        first[i] = -1
        second[i] = -1
    for i in range(n): depth[i] = -1
    depth[0] = 0
    queue[0] = 0
    var head = 0
    var tail = 1
    while head < tail:
        let vertex = queue[head]
        head += 1
        for i in range(degree[vertex]):
            let pos = vertex * 8 + i
            let next = adjacent[pos]
            if depth[next] >= 0: continue
            depth[next] = depth[vertex] + 1
            up[next] = vertex
            first[next] = weight[edge_at[pos]]
            queue[tail] = next
            tail += 1
    for level in range(1, 4):
        for vertex in range(n):
            let prev = (level - 1) * 8 + vertex
            let other = (level - 1) * 8 + up[prev]
            let dest = level * 8 + vertex
            up[dest] = up[other]
            let merged = mst_lifting_merge(first[prev], second[prev], first[other], second[other])
            first[dest] = merged[0]
            second[dest] = merged[1]
    var increase: Int64 = -1
    for edge in range(m):
        if selected[edge]: continue
        var a = u[edge]
        var b = v[edge]
        if depth[a] < depth[b]:
            let tmp = a
            a = b
            b = tmp
        var x: Int64 = -1
        var y: Int64 = -1
        let difference = depth[a] - depth[b]
        for level in range(4):
            if difference & (1 << level) != 0:
                let pos = level * 8 + a
                let merged = mst_lifting_merge(x, y, first[pos], second[pos])
                x = merged[0]
                y = merged[1]
                a = up[pos]
        if a != b:
            var level = 4
            while level > 0:
                level -= 1
                let pa = level * 8 + a
                let pb = level * 8 + b
                if up[pa] != up[pb]:
                    let left = mst_lifting_merge(x, y, first[pa], second[pa])
                    let both = mst_lifting_merge(left[0], left[1], first[pb], second[pb])
                    x = both[0]
                    y = both[1]
                    a = up[pa]
                    b = up[pb]
            let left = mst_lifting_merge(x, y, first[a], second[a])
            let both = mst_lifting_merge(left[0], left[1], first[b], second[b])
            x = both[0]
            y = both[1]
        var removed = y
        if weight[edge] > x: removed = x
        if removed >= 0 and removed < weight[edge]:
            let delta = weight[edge] - removed
            if increase < 0 or delta < increase: increase = delta
    if increase < 0: return 0
    return total + increase + 1
