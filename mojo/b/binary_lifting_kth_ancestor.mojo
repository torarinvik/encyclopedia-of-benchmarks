from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
from std.collections import List

fn append_word(mut bytes: List[UInt8], value: Int64):
    var bits = value
    for _ in range(8): bytes.append(UInt8(bits & 255)); bits >>= 8

@export("binary_lifting_kth_ancestor")
fn binary_lifting_kth_ancestor(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
        output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 4: return -1
    let nv = input[0]; let rootv = input[1]; let ev = input[2]; let qv = input[3]
    if nv < 1 or nv > 256 or rootv < 0 or rootv >= nv or ev != nv - 1 or qv < 0 or qv > 1024 or length != c_size_t(4 + 2 * ev + 2 * qv): return -1
    let n = Int(nv); let edge_count = Int(ev); let queries = Int(qv); let root = Int(rootv); let query_offset = 4 + 2 * edge_count
    var adj = List[Bool](capacity=n * n)
    for _ in range(n * n): adj.append(False)
    for i in range(edge_count):
        let a = input[4 + 2 * i]; let b = input[5 + 2 * i]
        if a < 0 or a >= nv or b < 0 or b >= nv or a == b: return -1
        adj[Int(a) * n + Int(b)] = True; adj[Int(b) * n + Int(a)] = True
    for i in range(queries):
        let v = input[query_offset + 2 * i]; let k = input[query_offset + 2 * i + 1]
        if v < 0 or v >= nv or k < 0: return -1
    var ancestors = List[Int](capacity=9 * n)
    for _ in range(9 * n): ancestors.append(root)
    var parent = List[Int](capacity=n); var seen = List[Bool](capacity=n); var q = List[Int](capacity=n)
    for _ in range(n): parent.append(-1); seen.append(False)
    parent[root] = root; seen[root] = True; q.append(root); var head = 0; var reached = 0
    while head < len(q):
        let u = q[head]; head += 1; reached += 1
        ancestors[u] = u
        for v in range(n):
            if adj[u * n + v]:
                if v == parent[u]: continue
                if seen[v]: return -1
                seen[v] = True; parent[v] = u; ancestors[v] = u; q.append(v)
    if reached != n: return -1
    for level in range(1, 9):
        for v in range(n): ancestors[level * n + v] = ancestors[(level - 1) * n + ancestors[(level - 1) * n + v]]
    var bytes = List[UInt8](capacity=(queries + 1) * 8); append_word(bytes, Int64(queries))
    for i in range(queries):
        var v = Int(input[query_offset + 2 * i]); let k = input[query_offset + 2 * i + 1]
        if k >= nv: v = root
        else:
            for bit in range(9):
                if (UInt64(k) & (UInt64(1) << bit)) != 0: v = ancestors[bit * n + v]
        append_word(bytes, Int64(v))
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(len(bytes)): return -2
    for i in range(len(bytes)): output[i] = bytes[i]
    return Int64(len(bytes))
