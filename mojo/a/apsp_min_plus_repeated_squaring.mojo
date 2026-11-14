from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
from std.collections import List

@export("apsp_min_plus_repeated_squaring")
fn apsp_min_plus_repeated_squaring(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
                                  output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 2 or length > 65: return -1
    let nv = input[0]
    if nv < 1 or nv > 8: return -1
    let n = Int(nv)
    if length != c_size_t(1+n*n): return -1
    var current = List[Int64](capacity=64)
    var next = List[Int64](capacity=64)
    for _ in range(64):
        current.append(0)
        next.append(0)
    for i in range(n):
        for j in range(n):
            let value = input[1+i*n+j]
            if (i == j and value != 0) or (i != j and value != 1000000 and (value < 1 or value > 1000)): return -1
            current[i*n+j] = value
    let bytes = 8*n*n
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(bytes): return -2
    var edge_bound = 1
    while edge_bound < n-1:
        for i in range(n):
            for j in range(n):
                var best = Int64(1000000)
                for k in range(n):
                    let left = current[i*n+k]
                    let right = current[k*n+j]
                    if left != 1000000 and right != 1000000:
                        best = min(best, left+right)
                next[i*n+j] = best
        for i in range(n*n): current[i] = next[i]
        edge_bound *= 2
    for i in range(n*n):
        var bits = bitcast[UInt64](current[i])
        for j in range(8):
            output[8*i+j] = UInt8(bits & UInt64(255))
            bits = bits >> 8
    return Int64(bytes)
