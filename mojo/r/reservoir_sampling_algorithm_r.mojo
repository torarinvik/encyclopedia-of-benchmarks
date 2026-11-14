from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
from std.collections import List

@export("reservoir_sampling_algorithm_r")
fn reservoir_sampling_algorithm_r(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
                                  output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 2 or length > 130: return -1
    let nv = input[0]
    let kv = input[1]
    if nv < 0 or nv > 64 or kv < 0 or kv > nv: return -1
    let n = Int(nv)
    let k = Int(kv)
    if length != c_size_t(2+2*n-k): return -1
    for i in range(n):
        if input[2+i] < -1000000 or input[2+i] > 1000000: return -1
    for i in range(k, n):
        if input[2+n+i-k] < 0 or input[2+n+i-k] > Int64(i): return -1
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(8*k): return -2
    var reservoir = List[Int64](capacity=64)
    for i in range(k): reservoir.append(input[2+i])
    for i in range(k, n):
        let draw = Int(input[2+n+i-k])
        if draw < k: reservoir[draw] = input[2+i]
    for i in range(k):
        var bits = bitcast[UInt64](reservoir[i])
        for j in range(8):
            output[8*i+j] = UInt8(bits & UInt64(255))
            bits = bits >> 8
    return Int64(8*k)
