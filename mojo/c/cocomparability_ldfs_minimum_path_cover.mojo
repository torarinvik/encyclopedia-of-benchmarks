from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
from std.collections import InlineArray

@export("cocomparability_ldfs_minimum_path_cover")
fn cocomparability_ldfs_minimum_path_cover(
    input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t
) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 1 or length > 18: return -1
    let n64 = input[0]
    if n64 < 1 or n64 > 8: return -1
    let n = Int(n64)
    if length != c_size_t(1 + 2 * n): return -1
    let full = (UInt32(1) << UInt32(n)) - UInt32(1)
    var adjacency = InlineArray[UInt32, 8](fill=0)
    var order = InlineArray[Int, 8](fill=0)
    var rank = InlineArray[Int, 8](fill=0)
    var seen_order = InlineArray[Bool, 8](fill=False)
    for v in range(n):
        let row = input[1 + v]
        if row < 0: return -1
        if UInt64(row) > UInt64(full): return -1
        if row & (Int64(1) << v) != 0: return -1
        adjacency[v] = UInt32(row)
    for u in range(n):
        for v in range(n):
            if (adjacency[u] >> UInt32(v)) & UInt32(1) != (adjacency[v] >> UInt32(u)) & UInt32(1): return -1
    for i in range(n):
        let value = input[1 + n + i]
        if value < 0 or value >= n64 or seen_order[Int(value)]: return -1
        order[i] = Int(value)
        rank[Int(value)] = i
        seen_order[Int(value)] = True
    for i in range(n):
        for j in range(i + 1, n):
            for k in range(j + 1, n):
                let a = order[i]
                let b = order[j]
                let c = order[k]
                if ((adjacency[a] >> UInt32(c)) & UInt32(1)) != 0 and ((adjacency[a] >> UInt32(b)) & UInt32(1)) == 0 and ((adjacency[b] >> UInt32(c)) & UInt32(1)) == 0: return -1

    var reached = InlineArray[Bool, 8](fill=False)
    var queue = InlineArray[Int, 8](fill=0)
    var head = 0
    var tail = 1
    queue[0] = 0
    reached[0] = True
    while head < tail:
        let u = queue[head]
        head += 1
        for v in range(n):
            if ((adjacency[u] >> UInt32(v)) & UInt32(1)) != 0 and not reached[v]:
                reached[v] = True
                queue[tail] = v
                tail += 1
    for v in range(n):
        if not reached[v]: return -1

    var labels = InlineArray[UInt64, 8](fill=0)
    var visited = InlineArray[Bool, 8](fill=False)
    var ldfs = InlineArray[Int, 8](fill=0)
    for step in range(1, n + 1):
        var chosen = -1
        for v in range(n):
            if not visited[v] and (chosen < 0 or labels[v] > labels[chosen] or (labels[v] == labels[chosen] and rank[v] > rank[chosen])):
                chosen = v
        ldfs[step - 1] = chosen
        visited[chosen] = True
        for v in range(n):
            if not visited[v] and ((adjacency[chosen] >> UInt32(v)) & UInt32(1)) != 0:
                labels[v] = (labels[v] >> UInt64(4)) | (UInt64(step) << UInt64(60))
    var position = InlineArray[Int, 8](fill=0)
    for i in range(n):
        position[ldfs[i]] = i

    for v in range(n): visited[v] = False
    var paths = 0
    while True:
        var current = -1
        for v in range(n):
            if not visited[v] and (current < 0 or position[v] > position[current]): current = v
        if current < 0: break
        paths += 1
        visited[current] = True
        while True:
            var next = -1
            for v in range(n):
                if not visited[v] and ((adjacency[current] >> UInt32(v)) & UInt32(1)) != 0 and (next < 0 or position[v] > position[next]): next = v
            if next < 0: break
            visited[next] = True
            current = next
    return Int64(paths)
