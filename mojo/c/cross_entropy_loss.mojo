from std.collections import InlineArray
from std.ffi import c_size_t
from std.math import log
from std.memory import ImmutAnyOrigin, UnsafePointer

@export("cross_entropy_loss")
fn cross_entropy_loss(values: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t) abi("C") -> Float64:
    if values == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 1: return -1.0e300
    let n = values[0]
    if n < 1 or n > 64 or length != 1 + 2 * n: return -1.0e300
    var terms = InlineArray[Float64, 64](0.0)
    for i in range(n):
        let a = values[1 + i]
        let p = values[1 + n + i]
        if a < 0 or a > 1000000 or p < 1 or p > 1000000: return -1.0e300
        let actual = Float64(a) / 1000000.0
        let predicted = Float64(p) / 1000000.0
        terms[i] = -actual * log(predicted)
    var total = 0.0
    for i in range(n): total += terms[i]
    return total
