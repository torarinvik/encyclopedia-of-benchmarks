from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
from std.collections import List

fn append_word(mut b: List[UInt8], v: Int64):
    var bits = v
    for _ in range(8): b.append(UInt8(bits & 255)); bits >>= 8

@export("bidirectional_search")
fn bidirectional_search(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
        output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 4: return -1
    let nv = input[0]; let sv = input[1]; let tv = input[2]; let ne = input[3]
    if nv < 1 or nv > 64 or sv < 0 or sv >= nv or tv < 0 or tv >= nv or ne < 0 or ne > 4032 or length != c_size_t(4 + 2 * ne): return -1
    let n = Int(nv); let m = Int(ne)
    var adj = List[List[Int]](capacity=n); var edge = List[Bool](capacity=n * n)
    for _ in range(n): adj.append(List[Int](capacity=n))
    for _ in range(n * n): edge.append(False)
    for i in range(m):
        let a = input[4 + 2 * i]; let b = input[5 + 2 * i]
        if a < 0 or a >= nv or b < 0 or b >= nv or a == b: return -1
        let key = Int(a) * n + Int(b)
        if edge[key]: return -1
        edge[key] = True; adj[Int(a)].append(Int(b))
    for a in range(n):
        for b in range(n):
            if edge[a * n + b] != edge[b * n + a]: return -1
    let start = Int(sv); let goal = Int(tv)
    var path = List[Int](capacity=n)
    if start == goal:
        path.append(start)
    else:
        var parent0 = List[Int](capacity=n); var parent1 = List[Int](capacity=n)
        var q0 = List[Int](capacity=n); var q1 = List[Int](capacity=n)
        for _ in range(n): parent0.append(-2); parent1.append(-2)
        parent0[start] = -1; parent1[goal] = -1; q0.append(start); q1.append(goal)
        var head0 = 0; var head1 = 0; var meet = -1
        while head0 < len(q0) and head1 < len(q1) and meet < 0:
            for side in range(2):
                let current = q0[head0] if side == 0 else q1[head1]
                if side == 0: head0 += 1
                else: head1 += 1
                for v in adj[current]:
                    if side == 0:
                        if parent0[v] != -2: continue
                        parent0[v] = current; q0.append(v)
                        if parent1[v] != -2: meet = v; break
                    else:
                        if parent1[v] != -2: continue
                        parent1[v] = current; q1.append(v)
                        if parent0[v] != -2: meet = v; break
                if meet >= 0: break
        if meet >= 0:
            var rev = List[Int](capacity=n); var v = meet
            while v >= 0: rev.append(v); v = parent0[v]
            for j in range(len(rev) - 1, -1, -1): path.append(rev[j])
            v = parent1[meet]
            while v >= 0: path.append(v); v = parent1[v]
    var bytes = List[UInt8](capacity=(1 + len(path)) * 8)
    append_word(bytes, Int64(len(path)))
    for v in path: append_word(bytes, Int64(v))
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(len(bytes)): return -2
    for i in range(len(bytes)): output[i] = bytes[i]
    return Int64(len(bytes))
