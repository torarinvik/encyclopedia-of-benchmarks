from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
from std.collections import List

@export("a_star_search")
fn a_star_search(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
                output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 5 or length > 8448:
        return -1
    let vv = input[0]
    let ee = input[1]
    let ss = input[2]
    let tt = input[3]
    if vv < 1 or vv > 256 or ee < 0 or ee > 4096 or ss < 0 or ss >= vv or tt < 0 or tt >= vv:
        return -1
    let v = Int(vv)
    let e = Int(ee)
    if length != c_size_t(4 + v + 2 * e):
        return -1
    var h = List[Int64](length=v, fill=0)
    var dist = List[Int64](length=v, fill=Int64.max)
    var parent = List[Int64](length=v, fill=-1)
    var opened = List[Bool](length=v, fill=False)
    var closed = List[Bool](length=v, fill=False)
    for i in range(v):
        h[i] = input[4 + i]
        if h[i] < 0 or h[i] > 1000000000:
            return -1
    if h[Int(tt)] != 0:
        return -1
    for i in range(e):
        let u = input[4 + v + 2 * i]
        let w = input[5 + v + 2 * i]
        if u < 0 or u >= vv or w < 0 or w >= vv or h[Int(u)] > h[Int(w)] + 1:
            return -1
    dist[Int(ss)] = 0
    opened[Int(ss)] = True
    while True:
        var best = -1
        for i in range(v):
            if not opened[i]:
                continue
            if best < 0 or dist[i] + h[i] < dist[best] + h[best] or (dist[i] + h[i] == dist[best] + h[best] and (dist[i] < dist[best] or (dist[i] == dist[best] and i < best))):
                best = i
        if best < 0:
            break
        opened[best] = False
        closed[best] = True
        if best == Int(tt):
            break
        for edge in range(e):
            if input[4 + v + 2 * edge] != Int64(best):
                continue
            let neighbor = Int(input[5 + v + 2 * edge])
            if closed[neighbor]:
                continue
            let candidate = dist[best] + 1
            if candidate < dist[neighbor]:
                dist[neighbor] = candidate
                parent[neighbor] = Int64(best)
                opened[neighbor] = True
    if dist[Int(tt)] == Int64.max:
        return 0
    var reversed = List[Int64](capacity=v)
    var current = Int64(tt)
    while current >= 0 and len(reversed) < v:
        reversed.append(current)
        if current == ss:
            break
        current = parent[Int(current)]
    if len(reversed) == 0 or reversed[len(reversed) - 1] != ss or len(reversed) - 1 > 30:
        return -1
    let path_len = len(reversed)
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(path_len):
        return -2
    for i in range(path_len):
        output[i] = UInt8(reversed[path_len - 1 - i])
    return Int64(path_len)
