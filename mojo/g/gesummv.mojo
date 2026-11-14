# Independent bounded implementation; see the package for PolyBench provenance.
from std.collections import List
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

@export("gesummv")
fn gesummv(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t) abi("C") -> Float64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length != 1: return -1.0e300
    let n0 = input[0]
    if n0 < 1 or n0 > 64: return -1.0e300
    let n = Int(n0)
    var x = List[Float64](length=n, fill=0.0)
    for i in range(n): x[i] = Float64(i % n) / Float64(n)
    var result: Float64 = 0.0
    for i in range(n):
        var first: Float64 = 0.0
        var second: Float64 = 0.0
        for j in range(n):
            let a = Float64((i * j + 1) % n) / Float64(n)
            let b = Float64((i * j + 2) % n) / Float64(n)
            first = a * x[j] + first
            second = b * x[j] + second
        result += 1.5 * first + 1.2 * second
    return result
