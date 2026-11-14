from std.collections import List
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

fn pmst_root(parents: List[Int], mut vertex: Int) -> Int:
    while parents[vertex] != vertex: vertex = parents[vertex]
    return vertex

@export("truthful_multicast_pmst_tree")
fn truthful_multicast_pmst_tree(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
        output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 4 or length > 95: return -1
    let n0 = input[0]; let m0 = input[1]; let source0 = input[2]; let r0 = input[3]
    if n0 < 2 or n0 > 8 or m0 < n0 - 1 or m0 > 28 or source0 < 0 or source0 >= n0 or r0 < 1 or r0 >= n0: return -1
    let n = Int(n0); let m = Int(m0); let source = Int(source0); let r = Int(r0)
    if length != c_size_t(4 + 3 * m + r): return -1
    var eu = List[Int](); var ev = List[Int](); var ew = List[Int64](); var order = List[Int]()
    var previous_u = -1; var previous_v = -1
    for i in range(m):
        let u0 = input[4 + 3 * i]; let v0 = input[5 + 3 * i]; let w = input[6 + 3 * i]
        if u0 < 0 or v0 <= u0 or v0 >= n0 or w < 1 or w > 100: return -1
        let u = Int(u0); let v = Int(v0)
        if i > 0 and (u < previous_u or (u == previous_u and v <= previous_v)): return -1
        eu.append(u); ev.append(v); ew.append(w); order.append(i)
        previous_u = u; previous_v = v
    var receivers = List[Int]()
    var last = -1
    for i in range(r):
        let x0 = input[4 + 3 * m + i]
        if x0 < 0 or x0 >= n0 or x0 == source0 or (i > 0 and x0 <= Int64(last)): return -1
        last = Int(x0); receivers.append(last)
    for i in range(1, m):
        let key = order[i]
        var j = i
        while j > 0:
            let prior = order[j - 1]
            if ew[prior] < ew[key] or (ew[prior] == ew[key] and
                    (eu[prior] < eu[key] or (eu[prior] == eu[key] and ev[prior] < ev[key])): break
            order[j] = prior; j -= 1
        order[j] = key
    var dsu = List[Int]()
    for i in range(n): dsu.append(i)
    var tree = List[Int]()
    for i in range(m):
        if len(tree) == n - 1: break
        let e = order[i]
        let x = pmst_root(dsu, eu[e]); let y = pmst_root(dsu, ev[e])
        if x != y: dsu[x] = y; tree.append(e)
    if len(tree) != n - 1: return -1
    var parent = List[Int](length=n, fill=-1)
    var parent_edge = List[Int](length=n, fill=-1)
    var queue = List[Int]()
    parent[source] = source; queue.append(source)
    var head = 0
    while head < len(queue):
        let x = queue[head]; head += 1
        for e in tree:
            var y = -1
            if eu[e] == x: y = ev[e]
            elif ev[e] == x: y = eu[e]
            if y >= 0 and parent[y] == -1:
                parent[y] = x; parent_edge[y] = e; queue.append(y)
    var keep = List[Bool](length=m, fill=False)
    for receiver in receivers:
        var vertex = receiver
        while vertex != source:
            if parent[vertex] < 0: return -1
            keep[parent_edge[vertex]] = True
            vertex = parent[vertex]
    var count = 0
    for e in range(m):
        if keep[e]: count += 1
    let bytes = 8 * (1 + 3 * count)
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(bytes): return -2
    var words = List[Int64]()
    words.append(Int64(count))
    for e in range(m):
        if keep[e]: words.append(Int64(eu[e])); words.append(Int64(ev[e])); words.append(ew[e])
    for word in range(len(words)):
        for byte in range(8): output[8 * word + byte] = UInt8((words[word] >> (8 * byte)) & 255)
    return Int64(bytes)
