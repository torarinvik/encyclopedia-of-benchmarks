# Bounded Christofides construction with exact odd-vertex matching.
from std.collections import List
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

@export("metric_tsp_christofides")
fn metric_tsp_christofides(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
                           output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 2 or length > 65: return -1
    let nv = input[0]
    if nv < 1 or nv > 8 or length != c_size_t(1+nv*nv): return -1
    let n = Int(nv)
    var distances = List[Int64](capacity=n*n)
    var processed = List[Bool](capacity=n*n)
    var multi = List[Int](capacity=n*n)
    for u in range(n):
        for v in range(n):
            let value = input[1+u*n+v]
            if value < 0 or value > 10000 or (u == v and value != 0): return -1
            distances.append(value); processed.append(False); multi.append(0)
    for u in range(n):
        for v in range(n):
            if distances[u*n+v] != distances[v*n+u]: return -1
            for k in range(n):
                if distances[u*n+v] > distances[u*n+k]+distances[k*n+v]: return -1
    var parent = List[Int](capacity=n)
    var degree = List[Int](capacity=n)
    var seen = List[Bool](capacity=n)
    for i in range(n):
        parent.append(i); degree.append(0); seen.append(False)
    var accepted = 0
    while accepted+1 < n:
        var best = Int64(10001)
        var a = 0
        var b = 0
        for u in range(n):
            for v in range(u+1,n):
                if not processed[u*n+v] and distances[u*n+v] < best:
                    best = distances[u*n+v]; a = u; b = v
        processed[a*n+b] = True
        var ra = a
        var rb = b
        while parent[ra] != ra: ra = parent[ra]
        while parent[rb] != rb: rb = parent[rb]
        if ra != rb:
            parent[rb] = ra
            multi[a*n+b] = 1; multi[b*n+a] = 1
            degree[a] += 1; degree[b] += 1
            accepted += 1
    var odd = List[Int](capacity=n)
    for i in range(n):
        if degree[i] % 2 != 0: odd.append(i)
    let count = len(odd)
    let full = (1 << count)-1
    var dp = List[Int64](capacity=full+1)
    var pick = List[Int](capacity=full+1)
    for _ in range(full+1):
        dp.append(1000000000); pick.append(-1)
    dp[0] = 0
    for mask in range(1,full+1):
        var first = 0
        while (mask & (1 << first)) == 0: first += 1
        let rest = mask ^ (1 << first)
        for j in range(first+1,count):
            if (rest & (1 << j)) != 0:
                let value = dp[rest ^ (1 << j)] + distances[odd[first]*n+odd[j]]
                if value < dp[mask]:
                    dp[mask] = value
                    pick[mask] = j
    var mask = full
    while mask != 0:
        var first = 0
        while (mask & (1 << first)) == 0: first += 1
        let second = pick[mask]
        let a = odd[first]
        let b = odd[second]
        multi[a*n+b] += 1; multi[b*n+a] += 1
        mask ^= (1 << first) | (1 << second)
    var stack = List[Int](capacity=16)
    var reverse = List[Int](capacity=16)
    var order = List[Int](capacity=n)
    stack.append(0)
    var top = 1
    while top > 0:
        let vertex = stack[top-1]
        var neighbor = 0
        while neighbor < n and multi[vertex*n+neighbor] == 0: neighbor += 1
        if neighbor < n:
            multi[vertex*n+neighbor] -= 1; multi[neighbor*n+vertex] -= 1
            if top < len(stack): stack[top] = neighbor
            else: stack.append(neighbor)
            top += 1
        else:
            reverse.append(vertex)
            top -= 1
    var i = len(reverse)
    while i > 0:
        i -= 1
        let vertex = reverse[i]
        if not seen[vertex]:
            seen[vertex] = True
            order.append(vertex)
    var cost = Int64(0)
    for j in range(n-1): cost += distances[order[j]*n+order[j+1]]
    cost += distances[order[n-1]*n]
    let bytes = 8*(n+2)
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(bytes): return -2
    for byte in range(8): output[byte] = UInt8((cost >> (8*byte)) & 255)
    for j in range(n):
        for byte in range(8): output[8*(j+1)+byte] = UInt8((Int64(order[j]) >> (8*byte)) & 255)
    for byte in range(8): output[8*(n+1)+byte] = 0
    return Int64(bytes)
