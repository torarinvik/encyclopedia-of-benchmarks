from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
from std.collections import List

@export("gapbs_shiloach_vishkin_components")
fn gapbs_shiloach_vishkin_components(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
                                      output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 2 or length > 130: return -1
    let nv = input[0]
    let mv = input[1]
    if nv < 1 or nv > 16 or mv < 0 or mv > 64: return -1
    let n = Int(nv)
    let m = Int(mv)
    if length != c_size_t(2+2*m): return -1
    var adj = List[Bool](capacity=256)
    var component = List[Int](capacity=16)
    for _ in range(256): adj.append(False)
    for i in range(16): component.append(i)
    for edge in range(m):
        let uv = input[2+2*edge]
        let vv = input[3+2*edge]
        if uv < 0 or vv <= uv or vv >= nv: return -1
        let u = Int(uv)
        let v = Int(vv)
        if adj[16*u+v]: return -1
        adj[16*u+v] = True
        adj[16*v+u] = True
    let bytes = 8*n
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(bytes): return -2
    var changed = True
    var rounds = 0
    while changed and rounds < n*n+1:
        changed = False
        for u in range(n):
            for v in range(n):
                if adj[16*u+v]:
                    let a = component[u]
                    let b = component[v]
                    if a != b:
                        let high = max(a, b)
                        let low = min(a, b)
                        if component[high] == high:
                            component[high] = low
                            changed = True
        for node in range(n):
            while component[node] != component[component[node]]:
                component[node] = component[component[node]]
        rounds += 1
    if changed: return -1
    for node in range(n):
        var bits = UInt64(component[node])
        for byte in range(8):
            output[8*node+byte] = UInt8(bits & UInt64(255))
            bits = bits >> 8
    return Int64(bytes)
