from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
from std.collections import InlineArray

comptime NMAX = 8
comptime MMAX = 24
comptime INPUT_MAX = 77

fn isap_dfs(u: Int, sink: Int, amount: Int64, n: Int,
            inout residual: InlineArray[Int64, 64], distance: InlineArray[Int64, 8],
            inout gap: InlineArray[Int64, 9], inout current: InlineArray[Int, 8],
            inout stopped: Int) -> Int64:
    if u == sink: return amount
    while current[u] < n:
        let v = current[u]
        let edge = u * 8 + v
        if residual[edge] > 0 and distance[u] == distance[v] + 1:
            let limit = amount if amount < residual[edge] else residual[edge]
            let sent = isap_dfs(v, sink, limit, n, inout residual, distance, inout gap, inout current, inout stopped)
            if sent > 0:
                residual[edge] -= sent
                residual[v * 8 + u] += sent
                return sent
            if stopped != 0: return 0
        current[u] += 1
    let old = distance[u]
    var best: Int64 = Int64(n)
    for v in range(n):
        if residual[u * 8 + v] > 0 and distance[v] < best: best = distance[v]
    let replacement = (best + 1) if (best + 1) < Int64(n) else Int64(n)
    gap[Int(old)] -= 1
    distance[u] = replacement
    gap[Int(replacement)] += 1
    current[u] = 0
    if old < Int64(n) and gap[Int(old)] == 0: stopped = 1
    return 0

@export("isap_maxflow")
fn isap_maxflow(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < c_size_t(4) or length > c_size_t(INPUT_MAX): return -1
    let nv = input[0]
    let mv = input[1]
    let sv = input[2]
    let tv = input[3]
    if nv < 2 or nv > NMAX or mv < 0 or mv > MMAX or sv < 0 or sv >= nv or tv < 0 or tv >= nv or sv == tv:
        return -1
    let n = Int(nv)
    let m = Int(mv)
    let source = Int(sv)
    let sink = Int(tv)
    if length != c_size_t(4 + 3 * m): return -1
    var residual = InlineArray[Int64, 64](fill=0)
    for e in range(m):
        let u = input[4 + 3 * e]
        let v = input[5 + 3 * e]
        let capacity = input[6 + 3 * e]
        if u < 0 or u >= nv or v < 0 or v >= nv or u == v or capacity < 0 or capacity > 100: return -1
        residual[Int(u) * 8 + Int(v)] += capacity
    var distance = InlineArray[Int64, 8](fill=Int64(n))
    var gap = InlineArray[Int64, 9](fill=0)
    var current = InlineArray[Int, 8](fill=0)
    var queue = InlineArray[Int, 8](fill=0)
    distance[sink] = 0
    queue[0] = sink
    var head = 0
    var tail = 1
    while head < tail:
        let v = queue[head]
        head += 1
        for p in range(n):
            if distance[p] == Int64(n) and residual[p * 8 + v] > 0:
                distance[p] = distance[v] + 1
                queue[tail] = p
                tail += 1
    if distance[source] >= Int64(n): return 0
    for v in range(n): gap[Int(distance[v])] += 1
    var flow: Int64 = 0
    var stopped = 0
    while distance[source] < Int64(n) and stopped == 0:
        flow += isap_dfs(source, sink, 2400, n, inout residual, distance, inout gap, inout current, inout stopped)
    return flow
