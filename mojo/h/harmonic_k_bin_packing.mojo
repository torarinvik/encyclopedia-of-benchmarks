# Independent bounded HARM(k) profile; see package attribution.
from std.collections import List
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

@export("harmonic_k_bin_packing")
fn harmonic_k_bin_packing(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
                           output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 3 or length > 34: return -1
    let kv = input[0]
    let nv = input[1]
    if kv < 3 or kv > 8 or nv < 1 or nv > 32 or length != c_size_t(2+nv): return -1
    let k = Int(kv)
    let n = Int(nv)
    for i in range(n):
        if input[2+i] < 1 or input[2+i] > 10000: return -1
    let bytes = 8*(n+1)
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(bytes): return -2
    var current = List[Int64](capacity=k)
    var remaining = List[Int64](capacity=k)
    var assignment = List[Int64](capacity=n)
    for _ in range(k):
        current.append(-1)
        remaining.append(0)
    var bins = Int64(0)
    for i in range(n):
        let size = input[2+i]
        var kind = k-1
        for c in range(k-1):
            if size*Int64(c+2) > 10000:
                kind = c
                break
        if current[kind] < 0 or size > remaining[kind]:
            current[kind] = bins
            bins += 1
            remaining[kind] = 10000
        assignment.append(current[kind])
        remaining[kind] -= size
    for byte in range(8): output[byte] = UInt8((bins >> (8*byte)) & 255)
    for i in range(n):
        for byte in range(8): output[8*(i+1)+byte] = UInt8((assignment[i] >> (8*byte)) & 255)
    return Int64(bytes)
