from std.collections import List
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

fn ard_reaches(n: Int, allowed: List[Bool], residual: List[Int64],
               start: Int, target: List[Bool]) -> Bool:
    if target[start]: return True
    var seen = List[Bool](length=8, fill=False)
    var queue = List[Int](length=8, fill=0)
    var head = 0
    var tail = 1
    seen[start] = True
    queue[0] = start
    while head < tail:
        let u = queue[head]
        head += 1
        for v in range(n):
            if not seen[v] and allowed[u * 8 + v] and residual[u * 8 + v] > 0:
                if target[v]: return True
                seen[v] = True
                queue[tail] = v
                tail += 1
    return False

fn ard_find_path(n: Int, in_region: List[Bool], allowed: List[Bool],
                 residual: List[Int64], target: List[Bool], excess: List[Int64],
                 mut parent: List[Int]) -> Int:
    for v in range(8): parent[v] = -1
    var queue = List[Int](length=8, fill=0)
    var head = 0
    var tail = 0
    for v in range(n):
        if in_region[v] and excess[v] > 0:
            parent[v] = v
            queue[tail] = v
            tail += 1
    while head < tail:
        let u = queue[head]
        head += 1
        for v in range(n):
            if parent[v] >= 0 or not allowed[u * 8 + v] or residual[u * 8 + v] <= 0: continue
            parent[v] = u
            if target[v]: return v
            queue[tail] = v
            tail += 1
    return -1

fn ard_discharge(n: Int, region_id: Int, source: Int, sink: Int,
                 boundary_count: Int, regions: List[Int64],
                 boundary_by_region: List[Bool], mut residual: List[Int64],
                 mut excess: List[Int64], mut labels: List[Int], flow_value: Int64) -> Int64:
    var in_region = List[Bool](length=8, fill=False)
    var external = List[Bool](length=8, fill=False)
    var inside_terminal = List[Bool](length=8, fill=False)
    var allowed = List[Bool](length=64, fill=False)
    var local = List[Int64](length=64, fill=0)
    for v in range(n):
        in_region[v] = v != source and v != sink and regions[v] == Int64(region_id)
        external[v] = boundary_by_region[region_id * 8 + v]
        inside_terminal[v] = in_region[v] or v == source or v == sink
    for u in range(n):
        for v in range(n):
            allowed[u * 8 + v] = (inside_terminal[u] and inside_terminal[v]) or
                (in_region[u] and external[v]) or (external[u] and in_region[v])
            if allowed[u * 8 + v] and not (external[u] and in_region[v]):
                local[u * 8 + v] = residual[u * 8 + v]
    var flow = flow_value
    for stage in range(boundary_count + 1):
        var target = List[Bool](length=8, fill=False)
        target[sink] = True
        for v in range(n):
            if external[v] and labels[v] < stage: target[v] = True
        while True:
            var parent = List[Int](length=8, fill=-1)
            let finish = ard_find_path(n, in_region, allowed, local, target, excess, mut parent)
            if finish < 0: break
            var path = List[Int](length=8, fill=0)
            var path_len = 0
            var vertex = finish
            while True:
                path[path_len] = vertex
                path_len += 1
                if parent[vertex] == vertex: break
                vertex = parent[vertex]
            let start = path[path_len - 1]
            var amount = excess[start]
            var i = path_len - 1
            while i > 0:
                let u = path[i]
                let v = path[i - 1]
                amount = min(amount, local[u * 8 + v])
                i -= 1
            i = path_len - 1
            while i > 0:
                let u = path[i]
                let v = path[i - 1]
                local[u * 8 + v] -= amount
                local[v * 8 + u] += amount
                residual[u * 8 + v] -= amount
                residual[v * 8 + u] += amount
                i -= 1
            excess[start] -= amount
            if finish == sink: flow += amount
            else: excess[finish] += amount
    for u in range(n):
        if in_region[u]:
            var next_label = boundary_count
            for stage in range(boundary_count + 1):
                var target = List[Bool](length=8, fill=False)
                target[sink] = True
                for v in range(n):
                    if external[v] and labels[v] < stage: target[v] = True
                if ard_reaches(n, allowed, local, u, target):
                    next_label = stage
                    break
            if next_label > labels[u]: labels[u] = next_label
    return flow

@export("region_discharge_path_push_relabel_maxflow")
fn region_discharge_path_push_relabel_maxflow(input: UnsafePointer[Int64, ImmutAnyOrigin],
                                               length: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < c_size_t(5) or length > c_size_t(50): return -1
    let rn = input[0]
    let rm = input[1]
    let rk = input[2]
    let rs = input[3]
    let rt = input[4]
    if rn < 4 or rn > 8 or rm < 1 or rm > 12 or rk < 2 or rk > 4 or rk > rn - 2 or
        rs < 0 or rs >= rn or rt < 0 or rt >= rn or rs == rt or
        length != c_size_t(5 + rn + 3 * rm): return -1
    let n = Int(rn)
    let m = Int(rm)
    let k = Int(rk)
    let source = Int(rs)
    let sink = Int(rt)
    var regions = List[Int64](length=8, fill=0)
    var seen = List[Bool](length=4, fill=False)
    var capacity = List[Int64](length=64, fill=0)
    var residual = List[Int64](length=64, fill=0)
    var boundary_by_region = List[Bool](length=32, fill=False)
    var boundary = List[Bool](length=8, fill=False)
    var excess = List[Int64](length=8, fill=0)
    var labels = List[Int](length=8, fill=0)
    for v in range(n):
        let raw = input[5 + v]
        if v == source or v == sink:
            if raw != -1: return -1
            regions[v] = -1
        else:
            if raw < 0 or raw >= rk: return -1
            regions[v] = raw
            seen[Int(raw)] = True
    for b in range(k):
        if not seen[b]: return -1
    for e in range(m):
        let p = 5 + n + 3 * e
        let ru = input[p]
        let rv = input[p + 1]
        let cap = input[p + 2]
        if ru < 0 or ru >= rn or rv < 0 or rv >= rn or ru == rv or rv == rs or ru == rt or cap < 0 or cap > 7: return -1
        let u = Int(ru)
        let v = Int(rv)
        capacity[u * 8 + v] += cap
        if cap > 0 and regions[u] >= 0 and regions[v] >= 0 and regions[u] != regions[v]:
            boundary[u] = True
            boundary[v] = True
            boundary_by_region[Int(regions[u]) * 8 + v] = True
            boundary_by_region[Int(regions[v]) * 8 + u] = True
    var boundary_count = 0
    for v in range(n):
        if boundary[v]: boundary_count += 1
    if boundary_count < 2: return -1
    for i in range(64): residual[i] = capacity[i]
    var flow: Int64 = 0
    for v in range(n):
        let amount = residual[source * 8 + v]
        if amount > 0:
            residual[source * 8 + v] = 0
            residual[v * 8 + source] += amount
            if v == sink: flow += amount
            else: excess[v] += amount
    labels[source] = boundary_count
    for sweep in range(2 * boundary_count * boundary_count + 1):
        for b in range(k):
            flow = ard_discharge(n, b, source, sink, boundary_count, regions,
                                 boundary_by_region, mut residual, mut excess, mut labels, flow)
        var active = False
        for v in range(n):
            if v != source and v != sink and excess[v] > 0 and labels[v] < boundary_count: active = True
        if not active: return flow
    return -1
