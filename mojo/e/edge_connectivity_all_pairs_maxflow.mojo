from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

comptime MAX_VERTICES = 10
comptime MAX_EDGES = 45
comptime MAX_PARSEABLE = 93

fn ecmf_pair_flow(adjacency: InlineArray[Int64, MAX_VERTICES * MAX_VERTICES],
                  n: Int, source: Int, sink: Int, limit: Int) -> Int:
    var residual = adjacency
    var flow = 0
    while flow < limit:
        var parent = InlineArray[Int, MAX_VERTICES](fill=-1)
        var queue = InlineArray[Int, MAX_VERTICES](fill=0)
        parent[source] = source
        var head = 0
        var tail = 1
        queue[0] = source
        while head < tail and parent[sink] < 0:
            let u = queue[head]
            head += 1
            for v in range(n):
                if parent[v] < 0 and residual[u * MAX_VERTICES + v] > 0:
                    parent[v] = u
                    queue[tail] = v
                    tail += 1
                    if v == sink: break
        if parent[sink] < 0: break
        var amount = limit - flow
        var v = sink
        while v != source:
            let u = parent[v]
            amount = min(amount, Int(residual[u * MAX_VERTICES + v]))
            v = u
        v = sink
        while v != source:
            let u = parent[v]
            residual[u * MAX_VERTICES + v] -= amount
            residual[v * MAX_VERTICES + u] += amount
            v = u
        flow += amount
    flow

@export("edge_connectivity_all_pairs_maxflow")
fn edge_connectivity_all_pairs_maxflow(input: UnsafePointer[Int64, ImmutAnyOrigin],
                                       length: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 2 or length > c_size_t(MAX_PARSEABLE): return -1
    let nv = input[0]
    let mv = input[1]
    if nv < 2 or nv > MAX_VERTICES or mv < 0 or mv > MAX_EDGES: return -1
    let n = Int(nv)
    let m = Int(mv)
    if Int(length) != 2 + 2 * m: return -1

    var adjacency = InlineArray[Int64, MAX_VERTICES * MAX_VERTICES](fill=0)
    for e in range(m):
        let left = input[2 + 2 * e]
        let right = input[3 + 2 * e]
        if left < 0 or right < 0 or left >= nv or right >= nv or left == right: return -1
        let u = Int(left)
        let v = Int(right)
        if adjacency[u * MAX_VERTICES + v] != 0: return -1
        adjacency[u * MAX_VERTICES + v] = 1
        adjacency[v * MAX_VERTICES + u] = 1

    var best = n - 1
    for source in range(n):
        for sink in range(source + 1, n):
            let flow = ecmf_pair_flow(adjacency, n, source, sink, best)
            if flow < best: best = flow
            if best == 0: return 0
    Int64(best)
