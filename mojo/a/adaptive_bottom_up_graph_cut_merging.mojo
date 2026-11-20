from std.collections import List
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

fn abm_allowed(u: Int, v: Int, n: Int, allowed: List[Int]) -> Bool:
    if u < n and allowed[u] == 0: return False
    if v < n and allowed[v] == 0: return False
    return v != n and u != n + 1

fn abm_augment(mut residual: List[Int64], n: Int, allowed: List[Int]) -> None:
    let source = n
    let sink = n + 1
    let size = n + 2
    while True:
        var parent = List[Int](length=10, fill=-1)
        var queue = List[Int](length=10, fill=0)
        parent[source] = source
        var head = 0
        var tail = 1
        queue[0] = source
        while head < tail and parent[sink] < 0:
            let u = queue[head]
            head += 1
            for v in range(size):
                if parent[v] < 0 and residual[u * 10 + v] > 0 and abm_allowed(u, v, n, allowed):
                    parent[v] = u
                    queue[tail] = v
                    tail += 1
                    if v == sink: break
        if parent[sink] < 0: return
        var amount = Int64(n * 7)
        var v = sink
        while v != source:
            let u = parent[v]
            amount = min(amount, residual[u * 10 + v])
            v = u
        v = sink
        while v != source:
            let u = parent[v]
            residual[u * 10 + v] -= amount
            residual[v * 10 + u] += amount
            v = u

fn abm_find(mut parent: List[Int], value: Int) -> Int:
    var root = value
    while parent[root] != root: root = parent[root]
    var node = value
    while parent[node] != node:
        let next = parent[node]
        parent[node] = root
        node = next
    return root

@export("adaptive_bottom_up_graph_cut_merging")
fn adaptive_bottom_up_graph_cut_merging(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 3 or length > 92: return -1
    let rn = input[0]
    let rm = input[1]
    let rb = input[2]
    if rn < 2 or rn > 8 or rm < 0 or rm > 16 or rb < 1 or rb > 4 or rb > rn or
        length != c_size_t(3 + 3 * rn + 4 * rm): return -1
    let n = Int(rn)
    let m = Int(rm)
    let bcount = Int(rb)
    var at = 3
    var block = List[Int](length=8, fill=0)
    var seen = List[Int](length=4, fill=0)
    for u in range(n):
        let value = input[at]
        at += 1
        if value < 0 or value >= rb: return -1
        block[u] = Int(value)
        seen[block[u]] = 1
    for b in range(bcount):
        if seen[b] == 0: return -1
    var source_cap = List[Int64](length=8, fill=0)
    var sink_cap = List[Int64](length=8, fill=0)
    for u in range(n):
        source_cap[u] = input[at]; at += 1
        if source_cap[u] < 0 or source_cap[u] > 7: return -1
    for u in range(n):
        sink_cap[u] = input[at]; at += 1
        if sink_cap[u] < 0 or sink_cap[u] > 7: return -1

    var eu = List[Int](length=16, fill=0)
    var ev = List[Int](length=16, fill=0)
    var ba = List[Int](length=16, fill=0)
    var bb = List[Int](length=16, fill=0)
    var uv = List[Int64](length=16, fill=0)
    var vu = List[Int64](length=16, fill=0)
    var cross = List[Int](length=16, fill=0)
    var enabled = List[Int](length=16, fill=0)
    var residual = List[Int64](length=100, fill=0)
    for u in range(n):
        residual[n * 10 + u] += source_cap[u]
        residual[u * 10 + n + 1] += sink_cap[u]
    var potential = List[Int64](length=16, fill=0)
    var present = List[Int](length=16, fill=0)
    for i in range(m):
        let ru = input[at]
        let rv = input[at + 1]
        let c = input[at + 2]
        let d = input[at + 3]
        at += 4
        if ru < 0 or ru >= rn or rv < 0 or rv >= rn or ru == rv or c < 0 or c > 7 or d < 0 or d > 7: return -1
        let u = Int(ru)
        let v = Int(rv)
        eu[i] = u; ev[i] = v; uv[i] = c; vu[i] = d
        if block[u] == block[v]:
            residual[u * 10 + v] += c
            residual[v * 10 + u] += d
        else:
            ba[i] = min(block[u], block[v])
            bb[i] = max(block[u], block[v])
            if c != 0 or d != 0:
                cross[i] = 1
                present[ba[i] * 4 + bb[i]] = 1

    var allowed = List[Int](length=8, fill=0)
    for b in range(bcount):
        for u in range(n): allowed[u] = Int(block[u] == b)
        abm_augment(residual, n, allowed)
    var tag = List[Int](length=8, fill=0)
    for b in range(bcount):
        for u in range(n): allowed[u] = Int(block[u] == b)
        var ss = List[Int](length=10, fill=0)
        var tt = List[Int](length=10, fill=0)
        var queue = List[Int](length=10, fill=0)
        var head = 0
        var tail = 1
        ss[n] = 1; queue[0] = n
        while head < tail:
            let u = queue[head]; head += 1
            for v in range(n + 2):
                if ss[v] == 0 and residual[u * 10 + v] > 0 and (u >= n or allowed[u] != 0) and (v >= n or allowed[v] != 0):
                    ss[v] = 1; queue[tail] = v; tail += 1
        head = 0; tail = 1; tt[n + 1] = 1; queue[0] = n + 1
        while head < tail:
            let v = queue[head]; head += 1
            for u in range(n + 2):
                if tt[u] == 0 and residual[u * 10 + v] > 0 and (u >= n or allowed[u] != 0) and (v >= n or allowed[v] != 0):
                    tt[u] = 1; queue[tail] = u; tail += 1
        for u in range(n):
            if allowed[u] != 0: tag[u] = 1 if ss[u] != 0 else (2 if tt[u] != 0 else 0)

    for i in range(m):
        if cross[i] != 0 and tag[eu[i]] != tag[ev[i]]:
            potential[ba[i] * 4 + bb[i]] += (Int64(1) if uv[i] > 0 else Int64(0)) + (Int64(1) if vu[i] > 0 else Int64(0))
    var order_a = List[Int](length=16, fill=0)
    var order_b = List[Int](length=16, fill=0)
    var order_n = 0
    for a in range(bcount):
        for b in range(a + 1, bcount):
            if present[a * 4 + b] == 0: continue
            var p = order_n; order_n += 1
            while p > 0:
                let pa = order_a[p - 1]; let pb = order_b[p - 1]
                let prior = potential[pa * 4 + pb]
                let current = potential[a * 4 + b]
                if prior > current or (prior == current and (pa < a or (pa == a and pb <= b))): break
                order_a[p] = pa; order_b[p] = pb; p -= 1
            order_a[p] = a; order_b[p] = b
    var parent = List[Int](length=4, fill=0)
    for b in range(bcount): parent[b] = b
    for oi in range(order_n):
        let a = abm_find(parent, order_a[oi])
        let b = abm_find(parent, order_b[oi])
        if a == b: continue
        let root = min(a, b)
        let other = max(a, b)
        parent[other] = root
        for i in range(m):
            if cross[i] == 0 or enabled[i] != 0: continue
            let x = abm_find(parent, ba[i])
            let y = abm_find(parent, bb[i])
            if x == y:
                residual[eu[i] * 10 + ev[i]] += uv[i]
                residual[ev[i] * 10 + eu[i]] += vu[i]
                enabled[i] = 1
        for u in range(n): allowed[u] = Int(abm_find(parent, block[u]) == root)
        abm_augment(residual, n, allowed)
    var flow = Int64(0)
    for u in range(n): flow += source_cap[u] - residual[n * 10 + u]
    return flow
