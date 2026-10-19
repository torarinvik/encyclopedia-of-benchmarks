from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

@export("tarjan_scc")
fn tarjan_scc(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
        output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 2 or length > 4096: return -1
    let nv = input[0]; let ne = input[1]
    if nv < 0 or nv > 40 or ne < 0 or ne > 2047 or length != c_size_t(2 + 2 * ne): return -1
    let n = Int(nv)
    var adj = InlineArray[UInt64, 40]()
    for e in range(Int(ne)):
        let u = input[2 + 2 * e]; let v = input[3 + 2 * e]
        if u < 0 or u >= nv or v < 0 or v >= nv: return -1
        adj[Int(u)] = adj[Int(u)] | (UInt64(1) << UInt64(v))
    var disc = InlineArray[Int64, 40](); var low = InlineArray[Int64, 40]()
    var parent = InlineArray[Int, 40](); var next = InlineArray[Int, 40]()
    var onstack = InlineArray[Bool, 40](); var stack = InlineArray[Int, 40]()
    var component = InlineArray[Int, 40](); var dfs = InlineArray[Int, 40]()
    for i in range(40): disc[i] = -1; low[i] = 0; parent[i] = -1; next[i] = 0; onstack[i] = False; component[i] = -1
    var sp = 0; var dp = 0; var tick = 0; var nc = 0
    for root in range(n):
        if disc[root] >= 0: continue
        disc[root] = tick; low[root] = tick; tick += 1
        stack[sp] = root; sp += 1; onstack[root] = True
        dfs[dp] = root; dp += 1
        while dp > 0:
            let v = dfs[dp - 1]
            var w = next[v]
            while w < n and (adj[v] & (UInt64(1) << UInt64(w))) == 0: w += 1
            if w < n:
                next[v] = w + 1
                if disc[w] < 0:
                    parent[w] = v; disc[w] = tick; low[w] = tick; tick += 1
                    stack[sp] = w; sp += 1; onstack[w] = True
                    dfs[dp] = w; dp += 1
                elif onstack[w] and disc[w] < low[v]:
                    low[v] = disc[w]
            else:
                dp -= 1
                if parent[v] >= 0 and low[v] < low[parent[v]]: low[parent[v]] = low[v]
                if low[v] == disc[v]:
                    while True:
                        sp -= 1; let member = stack[sp]
                        onstack[member] = False; component[member] = nc
                        if member == v: break
                    nc += 1
    var staged = InlineArray[UInt8, 81]()
    staged[0] = UInt8(nc); var pos = 1
    for first in range(n):
        let cid = component[first]
        var seen = False
        for j in range(first):
            if component[j] == cid: seen = True
        if seen: continue
        var size = 0
        for j in range(first, n):
            if component[j] == cid: size += 1
        staged[pos] = UInt8(size); pos += 1
        for j in range(first, n):
            if component[j] == cid: staged[pos] = UInt8(j); pos += 1
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(pos): return -2
    for i in range(pos): output[i] = staged[i]
    return Int64(pos)
