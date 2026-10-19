from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
from std.collections import List

fn bfs_path_put(out: UnsafePointer[UInt8, MutAnyOrigin], pos: Int, value: Int64) -> None:
    let bits = UInt64(value)
    for b in range(8): out[pos * 8 + b] = UInt8((bits >> (8 * b)) & 255)

@export("breadth_first_search_shortest_path")
fn breadth_first_search_shortest_path(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t, output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 4 or length > 516: return -1
    let nv = input[0]; let ev = input[1]; let sv = input[2]; let gv = input[3]
    if nv < 1 or nv > 32 or ev < 0 or ev > 256 or length != c_size_t(4 + 2 * ev) or sv < 0 or sv >= nv or gv < 0 or gv >= nv: return -1
    let n = Int(nv); let m = Int(ev); var adj = List[List[Int]](capacity=n)
    for _ in range(n): adj.append(List[Int](capacity=m))
    for e in range(m):
        let u = input[4 + 2 * e]; let v = input[5 + 2 * e]
        if u < 0 or u >= nv or v < 0 or v >= nv: return -1
        adj[Int(u)].append(Int(v))
    var parent = List[Int](capacity=n); var visited = List[Bool](capacity=n); var queue = List[Int](capacity=n)
    for _ in range(n): parent.append(-1); visited.append(False)
    visited[Int(sv)] = True; queue.append(Int(sv)); var head = 0
    while head < len(queue) and not visited[Int(gv)]:
        let u = queue[head]; head += 1
        for v in adj[u]:
            if not visited[v]: visited[v] = True; parent[v] = u; queue.append(v); if v == Int(gv): break
    var reverse = List[Int](capacity=n)
    if visited[Int(gv)]:
        var cur = Int(gv)
        while cur >= 0: reverse.append(cur); if cur == Int(sv): break; cur = parent[cur]
    let count = len(reverse); let required = (count + 1) * 8
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(required): return -2
    bfs_path_put(output, 0, Int64(count))
    for i in range(count): bfs_path_put(output, i + 1, Int64(reverse[count - 1 - i]))
    return Int64(required)
