# Deterministic greedy half-approximation for weighted Max-Cut.
from std.collections import List
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

@export("max_cut_sahni_gonzalez")
fn max_cut_sahni_gonzalez(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
                          output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 2 or length > 362: return -1
    let nv = input[0]
    let mv = input[1]
    if nv < 1 or nv > 16 or mv < 0 or mv > 120 or length != c_size_t(2+3*mv): return -1
    let n = Int(nv)
    let m = Int(mv)
    var weights = List[Int64](capacity=n*n)
    var seen = List[Bool](capacity=n*n)
    var sides = List[Int64](capacity=n)
    for _ in range(n*n):
        weights.append(0)
        seen.append(False)
    for _ in range(n): sides.append(0)
    for edge in range(m):
        let u = input[2+3*edge]
        let v = input[3+3*edge]
        let weight = input[4+3*edge]
        if u < 0 or v <= u or v >= nv or weight < 0 or weight > 10000: return -1
        let a = Int(u)
        let b = Int(v)
        if seen[a*n+b]: return -1
        seen[a*n+b] = True
        weights[a*n+b] = weight
        weights[b*n+a] = weight
    var cut = Int64(0)
    for vertex in range(n):
        var zero = Int64(0)
        var one = Int64(0)
        for prior in range(vertex):
            if sides[prior] == 1: zero += weights[prior*n+vertex]
            else: one += weights[prior*n+vertex]
        if one > zero:
            sides[vertex] = 1
            cut += one
        else:
            cut += zero
    let bytes = 8*(n+1)
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(bytes): return -2
    for byte in range(8): output[byte] = UInt8((cut >> (8*byte)) & 255)
    for i in range(n):
        for byte in range(8): output[8*(i+1)+byte] = UInt8((sides[i] >> (8*byte)) & 255)
    return Int64(bytes)
