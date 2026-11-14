# Independent bounded PolyBench correlation profile; see package LICENSE.txt.
from std.collections import InlineArray
from std.ffi import c_size_t
from std.math import isfinite, sqrt
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

@export("polybench_correlation")
fn polybench_correlation(input: UnsafePointer[Float64, ImmutAnyOrigin], length: c_size_t,
                          output: UnsafePointer[Float64, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Float64, ImmutAnyOrigin]() or length != 2: return -1
    let nv = input[0]; let mv = input[1]
    if not isfinite(nv) or not isfinite(mv) or nv < 1.0 or nv > 6.0 or mv < 1.0 or mv > 6.0: return -1
    let n = Int(nv); let m = Int(mv)
    if Float64(n) != nv or Float64(m) != mv: return -1
    let required = m*m
    if output == UnsafePointer[Float64, MutAnyOrigin]() or capacity < c_size_t(required): return -2
    var data = InlineArray[Float64, 36](fill=0.0)
    var correlation = InlineArray[Float64, 36](fill=0.0)
    var mean = InlineArray[Float64, 6](fill=0.0)
    var deviation = InlineArray[Float64, 6](fill=0.0)
    for i in range(n):
        for j in range(m): data[i*m+j] = Float64(i*j)/Float64(m)+Float64(i)
    for j in range(m):
        for i in range(n): mean[j] += data[i*m+j]
        mean[j] /= Float64(n)
    for j in range(m):
        for i in range(n):
            let delta = data[i*m+j]-mean[j]
            deviation[j] += delta*delta
        deviation[j] = sqrt(deviation[j]/Float64(n))
        if deviation[j] <= 0.1: deviation[j] = 1.0
    let root_n = sqrt(Float64(n))
    for i in range(n):
        for j in range(m):
            data[i*m+j] -= mean[j]
            data[i*m+j] /= root_n*deviation[j]
    for i in range(m):
        correlation[i*m+i] = 1.0
        for j in range(i+1,m):
            var sum = 0.0
            for k in range(n): sum += data[k*m+i]*data[k*m+j]
            correlation[i*m+j] = sum; correlation[j*m+i] = sum
    for i in range(required): output[i] = correlation[i]
    return Int64(required)
