# Deterministic Kruskal tree and preorder shortcutting for metric TSP.
from std.collections import List
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

@export("metric_tsp_tree_doubling")
fn metric_tsp_tree_doubling(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
                            output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 2 or length > 65: return -1
    let nv = input[0]
    if nv < 1 or nv > 8 or length != c_size_t(1+nv*nv): return -1
    let n = Int(nv)
    var distances = List[Int64](capacity=n*n)
    var processed = List[Bool](capacity=n*n)
    var tree = List[Bool](capacity=n*n)
    for u in range(n):
        for v in range(n):
            let value = input[1+u*n+v]
            if value < 0 or value > 10000 or (u == v and value != 0): return -1
            distances.append(value); processed.append(False); tree.append(False)
    for u in range(n):
        for v in range(n):
            if distances[u*n+v] != distances[v*n+u]: return -1
            for k in range(n):
                if distances[u*n+v] > distances[u*n+k]+distances[k*n+v]: return -1
    var parent = List[Int](capacity=n)
    var visited = List[Bool](capacity=n)
    var stack = List[Int](capacity=n)
    var order = List[Int](capacity=n)
    for i in range(n):
        parent.append(i); visited.append(False); stack.append(0)
    var accepted = 0
    while accepted+1 < n:
        var best_weight = Int64(10001)
        var best_u = 0
        var best_v = 0
        for u in range(n):
            for v in range(u+1,n):
                if not processed[u*n+v] and distances[u*n+v] < best_weight:
                    best_weight = distances[u*n+v]
                    best_u = u
                    best_v = v
        processed[best_u*n+best_v] = True
        var root_u = best_u
        var root_v = best_v
        while parent[root_u] != root_u: root_u = parent[root_u]
        while parent[root_v] != root_v: root_v = parent[root_v]
        if root_u != root_v:
            parent[root_v] = root_u
            tree[best_u*n+best_v] = True
            tree[best_v*n+best_u] = True
            accepted += 1
    var top = 1
    stack[0] = 0
    while top > 0:
        top -= 1
        let vertex = stack[top]
        if visited[vertex]: continue
        visited[vertex] = True
        order.append(vertex)
        var neighbor = n
        while neighbor > 0:
            neighbor -= 1
            if tree[vertex*n+neighbor] and not visited[neighbor]:
                stack[top] = neighbor
                top += 1
    var cost = Int64(0)
    for i in range(n-1): cost += distances[order[i]*n+order[i+1]]
    cost += distances[order[n-1]*n]
    let bytes = 8*(n+2)
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(bytes): return -2
    for byte in range(8): output[byte] = UInt8((cost >> (8*byte)) & 255)
    for i in range(n):
        for byte in range(8): output[8*(i+1)+byte] = UInt8((Int64(order[i]) >> (8*byte)) & 255)
    for byte in range(8): output[8*(n+1)+byte] = 0
    return Int64(bytes)
