# Independent bounded PolyBench Durbin profile; see package license.
from std.collections import List
from std.ffi import c_size_t
from std.math import isfinite
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

@export("durbin")
fn durbin(input: UnsafePointer[Float64, ImmutAnyOrigin], length: c_size_t,
          output: UnsafePointer[Float64, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Float64, ImmutAnyOrigin]() or length != 1: return -1
    let value = input[0]
    if not isfinite(value) or value < 1.0 or value > 40.0: return -1
    let n = Int(value)
    if Float64(n) != value: return -1
    if output == UnsafePointer[Float64, MutAnyOrigin]() or capacity < c_size_t(n): return -2
    var r = List[Float64](capacity=n)
    var y = List[Float64](capacity=n)
    var z = List[Float64](capacity=n)
    for i in range(n):
        r.append(Float64(n + 1 - i))
        y.append(0.0)
        z.append(0.0)
    y[0] = -r[0]
    var beta = Float64(1.0)
    var alpha = -r[0]
    for k in range(1, n):
        beta = (1.0 - alpha * alpha) * beta
        var sum = Float64(0.0)
        for i in range(k): sum += r[k-i-1] * y[i]
        alpha = -(r[k] + sum) / beta
        for i in range(k): z[i] = y[i] + alpha * y[k-i-1]
        for i in range(k): y[i] = z[i]
        y[k] = alpha
    for i in range(n): output[i] = y[i]
    return Int64(n)
