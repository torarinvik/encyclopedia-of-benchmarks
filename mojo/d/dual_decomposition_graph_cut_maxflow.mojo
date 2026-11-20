from std.collections import List
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

const OFFSET = Int64(7000)

fn dd_member(owner: List[Int], vertex: Int, side: Int) -> Bool:
    return owner[vertex] == side or owner[vertex] == 2

fn dd_solve(side: Int, n: Int, m: Int, owner: List[Int], source_cap: List[Int64], sink_cap: List[Int64],
            eu: List[Int], ev: List[Int], uv: List[Int64], vu: List[Int64], lambda: List[Int64],
            scale: Int64, mut labels: List[Int64]) -> Int64:
    let source = n
    let sink = n + 1
    let size = n + 2
    var residual = List[Int64](length=64, fill=0)
    var constant = Int64(0)
    var flow = Int64(0)
    var source_sum = Int64(0)
    var lambda_sum = Int64(0)
    for u in range(n):
        source_sum += source_cap[u]
        if dd_member(owner, u, side):
            let factor = scale // 2 if owner[u] == 2 else scale
            residual[source * 8 + u] += source_cap[u] * factor
            residual[u * 8 + sink] += sink_cap[u] * factor
        if owner[u] == 2:
            lambda_sum += lambda[u] if lambda[u] >= 0 else -lambda[u]
    for i in range(m):
        if dd_member(owner, eu[i], side) and dd_member(owner, ev[i], side):
            let factor = scale // 2 if owner[eu[i]] == 2 and owner[ev[i]] == 2 else scale
            residual[eu[i] * 8 + ev[i]] += uv[i] * factor
            residual[ev[i] * 8 + eu[i]] += vu[i] * factor
    for u in range(n):
        if owner[u] == 2:
            let q = lambda[u] if side == 0 else -lambda[u]
            if q >= 0: residual[source * 8 + u] += q
            else:
                residual[u * 8 + sink] += -q
                constant += q
    while True:
        var parent = List[Int](length=8, fill=-1)
        var queue = List[Int](length=8, fill=0)
        parent[source] = source
        var head = 0
        var tail = 1
        queue[0] = source
        while head < tail and parent[sink] < 0:
            let u = queue[head]
            head += 1
            for v in range(size):
                if parent[v] < 0 and residual[u * 8 + v] > 0:
                    parent[v] = u
                    queue[tail] = v
                    tail += 1
                    if v == sink: break
        if parent[sink] < 0:
            for u in range(n):
                labels[u] = Int64(1) if dd_member(owner, u, side) and parent[u] < 0 else Int64(0)
            return flow + constant
        var amount = source_sum * scale + lambda_sum + 1
        var v = sink
        while v != source:
            let u = parent[v]
            amount = min(amount, residual[u * 8 + v])
            v = u
        v = sink
        while v != source:
            let u = parent[v]
            residual[u * 8 + v] -= amount
            residual[v * 8 + u] += amount
            v = u
        flow += amount

@export("dual_decomposition_graph_cut_maxflow")
fn dual_decomposition_graph_cut_maxflow(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 4 or length > 63: return -1
    let rn = input[0]
    let rm = input[1]
    let ro = input[2]
    let rt = input[3]
    if rn < 3 or rn > 6 or rm < 0 or rm > 10 or ro < 1 or ro > 3 or rt < 1 or rt > 8 or
        length != c_size_t(4 + 3 * rn + 4 * rm): return -1
    let n = Int(rn)
    let m = Int(rm)
    let overlap = Int(ro)
    let rounds = Int(rt)
    var at = 4
    var owner = List[Int](length=6, fill=0)
    var counts = List[Int](length=3, fill=0)
    for u in range(n):
        let raw = input[at]
        at += 1
        if raw < 0 or raw > 2: return -1
        owner[u] = Int(raw)
        counts[owner[u]] += 1
    if counts[0] == 0 or counts[1] == 0 or counts[2] != overlap: return -1
    var source_cap = List[Int64](length=6, fill=0)
    var sink_cap = List[Int64](length=6, fill=0)
    for u in range(n):
        source_cap[u] = input[at]; at += 1
        if source_cap[u] < 0 or source_cap[u] > 6 or source_cap[u] % 2 != 0: return -1
    for u in range(n):
        sink_cap[u] = input[at]; at += 1
        if sink_cap[u] < 0 or sink_cap[u] > 6 or sink_cap[u] % 2 != 0: return -1
    var eu = List[Int](length=10, fill=0)
    var ev = List[Int](length=10, fill=0)
    var uv = List[Int64](length=10, fill=0)
    var vu = List[Int64](length=10, fill=0)
    for i in range(m):
        let ru = input[at]
        let rv = input[at + 1]
        let c = input[at + 2]
        let d = input[at + 3]
        at += 4
        if ru < 0 or ru >= rn or rv < 0 or rv >= rn or ru == rv or
            (owner[Int(ru)] == 0 and owner[Int(rv)] == 1) or (owner[Int(ru)] == 1 and owner[Int(rv)] == 0) or
            c < 0 or c > 6 or c % 2 != 0 or d < 0 or d > 6 or d % 2 != 0: return -1
        eu[i] = Int(ru); ev[i] = Int(rv); uv[i] = c; vu[i] = d
    var scales = List[Int64](length=9, fill=0)
    scales[1] = 2; scales[2] = 2; scales[3] = 6; scales[4] = 12
    scales[5] = 60; scales[6] = 60; scales[7] = 420; scales[8] = 840
    let scale = scales[rounds]
    var lambda = List[Int64](length=6, fill=0)
    var labels_m = List[Int64](length=6, fill=0)
    var labels_n = List[Int64](length=6, fill=0)
    var dual_scaled = Int64(0)
    var agreement = False
    for iteration in range(1, rounds + 1):
        let energy_m = dd_solve(0,n,m,owner,source_cap,sink_cap,eu,ev,uv,vu,lambda,scale,labels_m)
        let energy_n = dd_solve(1,n,m,owner,source_cap,sink_cap,eu,ev,uv,vu,lambda,scale,labels_n)
        dual_scaled = energy_m + energy_n
        agreement = True
        for u in range(n):
            if owner[u] == 2 and labels_m[u] != labels_n[u]: agreement = False
        if agreement or iteration == rounds: break
        let step = scale // iteration
        for u in range(n):
            if owner[u] == 2: lambda[u] += step * (labels_m[u] - labels_n[u])
    return 2 * (dual_scaled + OFFSET) + (Int64(1) if agreement else Int64(0))
