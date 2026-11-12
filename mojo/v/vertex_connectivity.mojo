from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

comptime MAX_N = 10
comptime MAX_M = 45
comptime MAX_INPUT = 92
comptime MAX_DN = 20

@export("vertex_connectivity")
fn vertex_connectivity(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 2 or length > c_size_t(MAX_INPUT): return -1
    let nv = input[0]
    let mv = input[1]
    if nv < 0 or nv > MAX_N or mv < 0 or mv > MAX_M: return -1
    let n = Int(nv)
    let m = Int(mv)
    if Int(length) != 2 + 2*m: return -1
    var adjacency = InlineArray[UInt64, MAX_N](fill=0)
    for e in range(m):
        let left = input[2+2*e]
        let right = input[3+2*e]
        if left < 0 or right < 0 or left >= nv or right >= nv: return -1
        if left != right:
            let u = Int(left)
            let v = Int(right)
            adjacency[u] |= UInt64(1) << UInt64(v)
            adjacency[v] |= UInt64(1) << UInt64(u)
    if n <= 1: return 0
    var reached: UInt64 = 1
    var graph_queue = InlineArray[Int, MAX_N](fill=0)
    var graph_head = 0
    var graph_tail = 1
    graph_queue[0] = 0
    while graph_head < graph_tail:
        let u = graph_queue[graph_head]
        graph_head += 1
        for v in range(n):
            let bit = UInt64(1) << UInt64(v)
            if (adjacency[u] & bit) != 0 and (reached & bit) == 0:
                reached |= bit
                graph_queue[graph_tail] = v
                graph_tail += 1
    if reached != ((UInt64(1) << UInt64(n)) - 1): return 0
    var best = n - 1
    for source in range(n):
        for target in range(source+1, n):
            if (adjacency[source] & (UInt64(1) << UInt64(target))) != 0: continue
            var residual = InlineArray[Int64, MAX_DN*MAX_DN](fill=0)
            let nodes = 2*n
            for v in range(n):
                let capacity = n if v == source or v == target else 1
                residual[(2*v)*MAX_DN+2*v+1] = Int64(capacity)
            for u in range(n):
                for v in range(u+1, n):
                    if (adjacency[u] & (UInt64(1) << UInt64(v))) != 0:
                        residual[(2*u+1)*MAX_DN+2*v] = 1
                        residual[(2*v+1)*MAX_DN+2*u] = 1
            let start = 2*source+1
            let sink = 2*target
            var flow: Int64 = 0
            while flow < Int64(best):
                var parent = InlineArray[Int, MAX_DN](fill=-1)
                var queue = InlineArray[Int, MAX_DN](fill=0)
                parent[start] = start
                var head = 0
                var tail = 1
                queue[0] = start
                while head < tail and parent[sink] < 0:
                    let u = queue[head]
                    head += 1
                    for v in range(nodes):
                        if parent[v] < 0 and residual[u*MAX_DN+v] > 0:
                            parent[v] = u
                            queue[tail] = v
                            tail += 1
                            if v == sink: break
                if parent[sink] < 0: break
                var amount = Int64(best) - flow
                var v = sink
                while v != start:
                    let u = parent[v]
                    amount = min(amount, residual[u*MAX_DN+v])
                    v = u
                v = sink
                while v != start:
                    let u = parent[v]
                    residual[u*MAX_DN+v] -= amount
                    residual[v*MAX_DN+u] += amount
                    v = u
                flow += amount
            if flow < Int64(best): best = Int(flow)
            if best == 0: return 0
    Int64(best)
