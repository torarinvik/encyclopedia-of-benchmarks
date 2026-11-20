# Clean-room Goldberg exact maximum-density profile.
from std.collections import List
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

@export("goldberg_maximum_density_subgraph")
fn goldberg_maximum_density_subgraph(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 2 or length > 59: return -1
    let nv = input[0]
    let mv = input[1]
    if nv < 2 or nv > 8 or mv < 0 or mv > 28 or length != c_size_t(2 + 2 * mv): return -1
    let n = Int(nv)
    let m = Int(mv)
    var rows = List[Int](capacity=n)
    var degree = List[Int](capacity=n)
    var edge_u = List[Int](capacity=m)
    var edge_v = List[Int](capacity=m)
    for _ in range(n):
        rows.append(0)
        degree.append(0)
    for e in range(m):
        let u64 = input[2 + 2 * e]
        let v64 = input[3 + 2 * e]
        if u64 < 0 or u64 >= v64 or v64 >= nv: return -1
        let u = Int(u64)
        let v = Int(v64)
        if (rows[u] & (1 << v)) != 0: return -1
        rows[u] |= 1 << v
        rows[v] |= 1 << u
        degree[u] += 1
        degree[v] += 1
        edge_u.append(u)
        edge_v.append(v)
    if m == 0: return 1

    var low = 0
    var high = m
    var denominator = 1
    var best_mask = 0
    while (high - low) * n * (n - 1) >= denominator:
        let low2 = 2 * low
        let high2 = 2 * high
        let midpoint = low + high
        let next_denominator = 2 * denominator
        let source = n
        let sink = n + 1
        let network_size = n + 2
        var residual = List[Int64](capacity=100)
        for _ in range(100): residual.append(0)
        for v in range(n):
            let source_capacity = m * next_denominator
            residual[source * 10 + v] = Int64(source_capacity)
            residual[v * 10 + sink] = Int64(source_capacity + 2 * midpoint - next_denominator * degree[v])
        for e in range(m):
            let u = edge_u[e]
            let v = edge_v[e]
            residual[u * 10 + v] += Int64(next_denominator)
            residual[v * 10 + u] += Int64(next_denominator)
        while True:
            var parent = List[Int](capacity=10)
            for _ in range(10): parent.append(-1)
            var queue = List[Int](capacity=10)
            var head = 0
            var tail = 0
            parent[source] = source
            queue.append(source)
            tail += 1
            while head < tail and parent[sink] == -1:
                let here = queue[head]
                head += 1
                for there in range(network_size):
                    if parent[there] == -1 and residual[here * 10 + there] > 0:
                        parent[there] = here
                        queue.append(there)
                        tail += 1
                        if there == sink: break
            if parent[sink] == -1: break
            var amount = Int64(1 << 60)
            var vertex = sink
            while vertex != source:
                let previous = parent[vertex]
                if residual[previous * 10 + vertex] < amount:
                    amount = residual[previous * 10 + vertex]
                vertex = previous
            vertex = sink
            while vertex != source:
                let previous = parent[vertex]
                residual[previous * 10 + vertex] -= amount
                residual[vertex * 10 + previous] += amount
                vertex = previous
        var reachable = List[Bool](capacity=10)
        for _ in range(10): reachable.append(False)
        var queue2 = List[Int](capacity=10)
        var head2 = 0
        var tail2 = 0
        reachable[source] = True
        queue2.append(source)
        tail2 += 1
        while head2 < tail2:
            let here = queue2[head2]
            head2 += 1
            for there in range(network_size):
                if not reachable[there] and residual[here * 10 + there] > 0:
                    reachable[there] = True
                    queue2.append(there)
                    tail2 += 1
        var selected = 0
        for v in range(n):
            if reachable[v]: selected |= 1 << v
        if selected != 0:
            low = midpoint
            high = high2
            best_mask = selected
        else:
            low = low2
            high = midpoint
        denominator = next_denominator
    var vertex_count = 0
    var edge_count = 0
    for v in range(n):
        if (best_mask & (1 << v)) != 0: vertex_count += 1
    if vertex_count == 0: return 1
    for e in range(m):
        let u = edge_u[e]
        let v = edge_v[e]
        if (best_mask & (1 << u)) != 0 and (best_mask & (1 << v)) != 0:
            edge_count += 1
    var a = edge_count
    var b = vertex_count
    while b != 0:
        let r = a % b
        a = b
        b = r
    return Int64((edge_count // a) * (n + 1) + vertex_count // a)
