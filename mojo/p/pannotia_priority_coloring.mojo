# Synchronous maximum and optional minimum priority coloring rounds.
from std.collections import List
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

@export("pannotia_priority_coloring")
fn pannotia_priority_coloring(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
                              output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 3 or length > 147: return -1
    let nv = input[0]
    let mv = input[1]
    let mode = input[2]
    if nv < 1 or nv > 16 or mv < 0 or mv > 64 or mode < 0 or mode > 1 or length != c_size_t(3+nv+2*mv): return -1
    let n = Int(nv)
    let m = Int(mv)
    var priorities = List[Int64](capacity=n)
    var adjacency = List[Int](capacity=n)
    var degree = List[Int](capacity=n)
    var colors = List[Int64](capacity=n)
    for v in range(n):
        let priority = input[3+v]
        if priority < 0 or priority > 99999998: return -1
        for u in range(v):
            if priorities[u] == priority: return -1
        priorities.append(priority); adjacency.append(0); degree.append(0); colors.append(-1)
    for e in range(m):
        let u = input[3+n+2*e]
        let v = input[4+n+2*e]
        if u < 0 or v <= u or v >= nv: return -1
        let a = Int(u)
        let b = Int(v)
        if (adjacency[a] & (1 << b)) != 0: return -1
        adjacency[a] |= 1 << b; adjacency[b] |= 1 << a
        degree[a] += 1; degree[b] += 1
    for v in range(n):
        if degree[v] == 1: return -1
    var active = (1 << n)-1
    var color = Int64(1)
    while active != 0:
        var chosen = 0
        for v in range(n):
            if (active & (1 << v)) == 0: continue
            var maximum = Int64(-1)
            var minimum = Int64(99999999)
            for u in range(n):
                if (active & (1 << u)) != 0 and (adjacency[v] & (1 << u)) != 0:
                    if priorities[u] > maximum: maximum = priorities[u]
                    if priorities[u] < minimum: minimum = priorities[u]
            if priorities[v] > maximum:
                colors[v] = color
                chosen |= 1 << v
            if mode == 1 and priorities[v] < minimum:
                colors[v] = color+1
                chosen |= 1 << v
        if chosen == 0: return -1
        active &= ~chosen
        if mode == 1: color += 2
        else: color += 1
    let bytes = 8*n
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(bytes): return -2
    for v in range(n):
        for byte in range(8): output[8*v+byte] = UInt8((colors[v] >> (8*byte)) & 255)
    return Int64(bytes)
