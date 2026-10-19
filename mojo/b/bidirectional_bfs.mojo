from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
from std.collections import List

fn put_word(mut bytes: List[UInt8], v: Int64):
    var bits = v
    for _ in range(8): bytes.append(UInt8(bits & 255)); bits >>= 8

@export("bidirectional_bfs")
fn bidirectional_bfs(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
        output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 4: return -1
    let nv = input[0]; let ne = input[1]; let sv = input[2]; let tv = input[3]
    if nv < 1 or nv > 64 or ne < 0 or ne > 4096 or sv < 0 or sv >= nv or tv < 0 or tv >= nv or length != c_size_t(4 + 2 * ne): return -1
    let n = Int(nv); let m = Int(ne)
    var edge = List[Bool](capacity=n * n); var adj = List[List[Int]](capacity=n)
    for _ in range(n * n): edge.append(False)
    for _ in range(n): adj.append(List[Int](capacity=n))
    for i in range(m):
        let a = input[4 + 2 * i]; let b = input[5 + 2 * i]
        if a < 0 or a >= nv or b < 0 or b >= nv: return -1
        if not edge[Int(a) * n + Int(b)]: edge[Int(a) * n + Int(b)] = True; adj[Int(a)].append(Int(b))
    for a in range(n):
        for b in range(n):
            if edge[a * n + b] != edge[b * n + a]: return -1
    let start = Int(sv); let goal = Int(tv)
    var path = List[Int](capacity=n)
    if start == goal: path.append(start)
    else:
        var seen0 = List[Bool](capacity=n); var seen1 = List[Bool](capacity=n)
        var p0 = List[Int](capacity=n); var p1 = List[Int](capacity=n)
        for _ in range(n): seen0.append(False); seen1.append(False); p0.append(-1); p1.append(-1)
        var q0 = List[Int](capacity=n); var q1 = List[Int](capacity=n)
        seen0[start] = True; seen1[goal] = True; q0.append(start); q1.append(goal)
        var h0 = 0; var h1 = 0; var meet = -1
        while h0 < len(q0) and h1 < len(q1) and meet < 0:
            let end0 = len(q0)
            while h0 < end0:
                let u = q0[h0]; h0 += 1
                for v in adj[u]:
                    if not seen0[v]: seen0[v] = True; p0[v] = u; q0.append(v)
            for v in range(n):
                if seen0[v] and seen1[v]: meet = v; break
            if meet >= 0: break
            let end1 = len(q1)
            while h1 < end1:
                let u = q1[h1]; h1 += 1
                for v in adj[u]:
                    if not seen1[v]: seen1[v] = True; p1[v] = u; q1.append(v)
            for v in range(n):
                if seen0[v] and seen1[v]: meet = v; break
        if meet >= 0:
            var rev = List[Int](capacity=n); var v = meet
            while v >= 0: rev.append(v); v = p0[v]
            for j in range(len(rev) - 1, -1, -1): path.append(rev[j])
            v = p1[meet]
            while v >= 0: path.append(v); v = p1[v]
    var bytes = List[UInt8](capacity=(1 + len(path)) * 8)
    put_word(bytes, Int64(len(path))); for v in path: put_word(bytes, Int64(v))
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(len(bytes)): return -2
    for i in range(len(bytes)): output[i] = bytes[i]
    return Int64(len(bytes))
