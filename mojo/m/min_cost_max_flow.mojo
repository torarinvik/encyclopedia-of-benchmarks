# Independent bounded implementation of the AtCoder min-cost-flow operation;
# source and CC0 notice are recorded in benchmarks/m/min_cost_max_flow.
from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

@export("min_cost_max_flow")
fn min_cost_max_flow(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
                     output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 5 or length > 69: return -1
    if input[0] < 2 or input[0] > 8 or input[1] < 0 or input[1] > 16: return -1
    let n = Int(input[0]); let m = Int(input[1])
    if length != c_size_t(5+4*m): return -1
    if input[2] < 0 or input[2] >= Int64(n) or input[3] < 0 or input[3] >= Int64(n) or input[2] == input[3] or input[4] < 0 or input[4] > 16: return -1
    let source = Int(input[2]); let sink = Int(input[3]); let limit = input[4]
    var from_vertex = InlineArray[Int, 32](fill=0)
    var to_vertex = InlineArray[Int, 32](fill=0)
    var residual = InlineArray[Int64, 32](fill=0)
    var edge_cost = InlineArray[Int64, 32](fill=0)
    for i in range(m):
        let u = input[5+4*i]; let v = input[6+4*i]
        let cap = input[7+4*i]; let cost = input[8+4*i]
        if u < 0 or u >= Int64(n) or v < 0 or v >= Int64(n) or cap < 0 or cap > 5 or cost < 0 or cost > 20: return -1
        from_vertex[2*i] = Int(u); to_vertex[2*i] = Int(v)
        from_vertex[2*i+1] = Int(v); to_vertex[2*i+1] = Int(u)
        residual[2*i] = cap; edge_cost[2*i] = cost; edge_cost[2*i+1] = -cost
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < 16: return -2
    var potential = InlineArray[Int64, 8](fill=0)
    var total_flow: Int64 = 0; var total_cost: Int64 = 0
    let inf: Int64 = 1 << 60
    while total_flow < limit:
        var dist = InlineArray[Int64, 8](fill=inf)
        var parent = InlineArray[Int, 8](fill=-1)
        var visited = InlineArray[Bool, 8](fill=False)
        dist[source] = 0
        for _ in range(n):
            var chosen = -1
            for v in range(n):
                if not visited[v] and dist[v] != inf and (chosen < 0 or dist[v] < dist[chosen]): chosen = v
            if chosen < 0: break
            visited[chosen] = True
            for e in range(2*m):
                if from_vertex[e] != chosen or residual[e] <= 0: continue
                let v = to_vertex[e]
                let candidate = dist[chosen] + edge_cost[e] + potential[chosen] - potential[v]
                if not visited[v] and candidate < dist[v]:
                    dist[v] = candidate; parent[v] = e
        if dist[sink] == inf: break
        for v in range(n):
            if dist[v] != inf: potential[v] += dist[v]
        var amount = limit-total_flow
        var vertex = sink
        while vertex != source:
            let e = parent[vertex]
            if e < 0: return -1
            if residual[e] < amount: amount = residual[e]
            vertex = from_vertex[e]
        vertex = sink
        while vertex != source:
            let e = parent[vertex]
            residual[e] -= amount; residual[e ^ 1] += amount
            total_cost += amount*edge_cost[e]
            vertex = from_vertex[e]
        total_flow += amount
    let flow_bits = UInt64(total_flow)
    let cost_bits = UInt64(total_cost)
    for b in range(8):
        output[b] = UInt8((flow_bits >> (8*b)) & 255)
        output[8+b] = UInt8((cost_bits >> (8*b)) & 255)
    return 16
