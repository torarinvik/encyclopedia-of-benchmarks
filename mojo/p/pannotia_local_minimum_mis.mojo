# Synchronous local-minimum priority MIS rounds.
from std.collections import List
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

@export("pannotia_local_minimum_mis")
fn pannotia_local_minimum_mis(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
                              output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 2 or length > 146: return -1
    let nv = input[0]
    let mv = input[1]
    if nv < 1 or nv > 16 or mv < 0 or mv > 64 or length != c_size_t(2+nv+2*mv): return -1
    let n = Int(nv)
    let m = Int(mv)
    var priorities = List[Int64](capacity=n)
    var adjacency = List[Int](capacity=n)
    for v in range(n):
        let priority = input[2+v]
        if priority < 0 or priority > 99999998: return -1
        for u in range(v):
            if priorities[u] == priority: return -1
        priorities.append(priority)
        adjacency.append(0)
    for e in range(m):
        let u = input[2+n+2*e]
        let v = input[3+n+2*e]
        if u < 0 or v <= u or v >= nv: return -1
        let a = Int(u)
        let b = Int(v)
        if (adjacency[a] & (1 << b)) != 0: return -1
        adjacency[a] |= 1 << b
        adjacency[b] |= 1 << a
    var active = (1 << n)-1
    var selected = 0
    while active != 0:
        var chosen = 0
        for v in range(n):
            if (active & (1 << v)) == 0: continue
            var minimum = True
            for u in range(n):
                if (active & (1 << u)) != 0 and (adjacency[v] & (1 << u)) != 0 and priorities[u] < priorities[v]: minimum = False
            if minimum: chosen |= 1 << v
        if chosen == 0: return -1
        selected |= chosen
        active &= ~chosen
        for v in range(n):
            if (chosen & (1 << v)) != 0: active &= ~adjacency[v]
    let bytes = 8*n
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(bytes): return -2
    for v in range(n):
        var value = Int64(0)
        if (selected & (1 << v)) != 0: value = 2
        for byte in range(8): output[8*v+byte] = UInt8((value >> (8*byte)) & 255)
    return Int64(bytes)
