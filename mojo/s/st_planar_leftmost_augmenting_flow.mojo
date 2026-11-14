from std.collections import List
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

@export("st_planar_leftmost_augmenting_flow")
fn st_planar_leftmost_augmenting_flow(input: UnsafePointer[Int64, ImmutAnyOrigin],
        length: c_size_t, output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 4 or length > 60: return -1
    let n0 = input[0]; let m0 = input[1]; let s0 = input[2]; let t0 = input[3]
    if n0 < 2 or n0 > 6 or m0 < 1 or m0 > 10 or s0 < 0 or s0 >= n0 or t0 < 0 or t0 >= n0 or s0 == t0: return -1
    let n = Int(n0); let m = Int(m0); let source = Int(s0); let sink = Int(t0)
    if Int(length) < 4 + 3 * m: return -1
    var u = List[Int](); var v = List[Int](); var cap = List[Int64]()
    var pairs = List[Bool](length=n * n, fill=False)
    var at = 4
    for _ in range(m):
        let x0 = input[at]; let y0 = input[at + 1]; let c = input[at + 2]; at += 3
        if x0 < 0 or x0 >= n0 or y0 < 0 or y0 >= n0 or x0 == y0 or c < 0 or c > 5: return -1
        let x = Int(x0); let y = Int(y0)
        if pairs[x * n + y]: return -1
        pairs[x * n + y] = True; pairs[y * n + x] = True
        u.append(x); v.append(y); cap.append(c)
    var degree = List[Int](length=n, fill=0)
    var rotation = List[Int](length=n * 6, fill=0)
    var seen = List[Bool](length=n * m, fill=False)
    var occurrences = List[Int](length=2 * m, fill=0)
    for x in range(n):
        if at >= Int(length): return -1
        let d0 = input[at]; at += 1
        if d0 < 0 or d0 >= n0 or at + Int(d0) > Int(length): return -1
        degree[x] = Int(d0)
        for j in range(Int(d0)):
            let e0 = input[at]; at += 1
            if e0 < 0 or e0 >= m0: return -1
            let e = Int(e0)
            if seen[x * m + e]: return -1
            seen[x * m + e] = True; rotation[x * 6 + j] = e
            if u[e] == x: occurrences[2 * e] += 1
            elif v[e] == x: occurrences[2 * e + 1] += 1
            else: return -1
    if at != Int(length): return -1
    for e in range(m):
        if occurrences[2 * e] != 1 or occurrences[2 * e + 1] != 1: return -1
    var connected = List[Bool](length=n, fill=False)
    var queue = List[Int]()
    connected[source] = True; queue.append(source)
    var head = 0
    while head < len(queue):
        let x = queue[head]; head += 1
        for y in range(n):
            if pairs[x * n + y] and not connected[y]: connected[y] = True; queue.append(y)
    if len(queue) != n: return -1
    var flow = List[Int64](length=m, fill=0)
    var total = Int64(0)
    while True:
        var visited = List[Bool](length=n, fill=False)
        var parent = List[Int](length=n, fill=-1)
        var parent_edge = List[Int](length=n, fill=-1)
        var direction = List[Int64](length=n, fill=0)
        var next = List[Int](length=n, fill=0)
        var stack = List[Int]()
        visited[source] = True; stack.append(source)
        while len(stack) > 0 and not visited[sink]:
            let x = stack[len(stack) - 1]
            if next[x] >= degree[x]:
                _ = stack.pop()
                continue
            let e = rotation[x * 6 + next[x]]; next[x] += 1
            var y = u[e]; var remaining = flow[e]; var sign = Int64(-1)
            if u[e] == x: y = v[e]; remaining = cap[e] - flow[e]; sign = 1
            if remaining > 0 and not visited[y]:
                visited[y] = True; parent[y] = x; parent_edge[y] = e; direction[y] = sign
                stack.append(y)
        if not visited[sink]: break
        var amount = Int64(6)
        var y = sink
        while y != source:
            let x = parent[y]; let e = parent_edge[y]
            var remaining = flow[e]
            if u[e] == x: remaining = cap[e] - flow[e]
            if remaining < amount: amount = remaining
            y = x
        y = sink
        while y != source:
            flow[parent_edge[y]] += direction[y] * amount
            y = parent[y]
        total += amount
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < 8: return -2
    for byte in range(8): output[byte] = UInt8((total >> (8 * byte)) & 255)
    return 8
