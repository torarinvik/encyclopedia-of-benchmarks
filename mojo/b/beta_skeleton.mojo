# Independently written beta=2 lune profile; see the package MIT notice.
from std.collections import List
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

fn squared_distance(x1: Int64, y1: Int64, x2: Int64, y2: Int64) -> Int64:
    let dx = x1 - x2
    let dy = y1 - y2
    return dx * dx + dy * dy

@export("beta_skeleton")
fn beta_skeleton(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
                 output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 3 or length > 65: return -1
    let nv = input[0]
    if nv < 1 or nv > 32 or length != c_size_t(1 + 2*nv): return -1
    let n = Int(nv)
    var xs = List[Int64](capacity=n)
    var ys = List[Int64](capacity=n)
    for i in range(n):
        let x = input[1+2*i]
        let y = input[2+2*i]
        if x < -1000 or x > 1000 or y < -1000 or y > 1000: return -1
        for j in range(i):
            if xs[j] == x and ys[j] == y: return -1
        xs.append(x)
        ys.append(y)
    var edges = List[UInt8](capacity=992)
    for i in range(n):
        for j in range(i+1, n):
            let distance = squared_distance(xs[i], ys[i], xs[j], ys[j])
            var blocked = False
            for k in range(n):
                if k != i and k != j:
                    if squared_distance(xs[k], ys[k], xs[i], ys[i]) < distance and squared_distance(xs[k], ys[k], xs[j], ys[j]) < distance:
                        blocked = True
                        break
            if not blocked:
                edges.append(UInt8(i))
                edges.append(UInt8(j))
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(len(edges)): return -2
    for i in range(len(edges)): output[i] = edges[i]
    return Int64(len(edges))
