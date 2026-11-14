# Independent bounded geometric-routing profile; see package attribution.
from std.collections import List
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

@export("geometric_greedy_compass_routing")
fn geometric_greedy_compass_routing(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
                                    output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 12 or length > 84: return -1
    let nv = input[0]
    let mode = input[1]
    let source = input[2]
    let target = input[3]
    if nv < 2 or nv > 8 or mode < 0 or mode > 1 or source < 0 or source >= nv or target < 0 or target >= nv: return -1
    let n = Int(nv)
    if length != c_size_t(4+2*n+n*n): return -1
    let adj = 4+2*n
    var xs = List[Int64](capacity=n)
    var ys = List[Int64](capacity=n)
    for i in range(n):
        let x = input[4+i]
        let y = input[4+n+i]
        if x < -8 or x > 8 or y < -8 or y > 8: return -1
        for j in range(i):
            if xs[j] == x and ys[j] == y: return -1
        xs.append(x)
        ys.append(y)
    for u in range(n):
        for v in range(n):
            let edge = input[adj+u*n+v]
            if (edge != 0 and edge != 1) or (u == v and edge != 0) or edge != input[adj+v*n+u]: return -1
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < 80: return -2
    var path = List[Int](capacity=n)
    var visited = 1 << Int(source)
    var current = Int(source)
    let goal = Int(target)
    path.append(current)
    while current != goal and len(path) < n:
        let tx = xs[goal]-xs[current]
        let ty = ys[goal]-ys[current]
        var best = -1
        var best_dot = Int64(0)
        var best_length = Int64(1)
        var best_distance = Int64(0)
        for v in range(n):
            if input[adj+current*n+v] != 1: continue
            let dx = xs[v]-xs[current]
            let dy = ys[v]-ys[current]
            var better = best == -1
            if mode == 0:
                let rx = xs[v]-xs[goal]
                let ry = ys[v]-ys[goal]
                let distance = rx*rx+ry*ry
                if not better: better = distance < best_distance or (distance == best_distance and v < best)
                if better: best_distance = distance
            else:
                let dot = dx*tx+dy*ty
                let squared = dx*dx+dy*dy
                if not better:
                    if (dot >= 0) != (best_dot >= 0):
                        better = dot >= 0
                    else:
                        let left = dot*dot*best_length
                        let right = best_dot*best_dot*squared
                        if dot >= 0: better = left > right or (left == right and v < best)
                        else: better = left < right or (left == right and v < best)
                if better:
                    best_dot = dot
                    best_length = squared
            if better: best = v
        if best == -1 or (visited & (1 << best)) != 0: break
        visited |= 1 << best
        current = best
        path.append(current)
    var record = List[Int64](capacity=10)
    var delivered = Int64(0)
    if current == goal: delivered = 1
    record.append(delivered)
    record.append(Int64(len(path)-1))
    for i in range(8):
        if i < len(path): record.append(Int64(path[i]))
        else: record.append(-1)
    for i in range(10):
        for byte in range(8): output[8*i+byte] = UInt8((record[i] >> (8*byte)) & 255)
    return 80
