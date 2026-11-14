# Rodinia seven-ellipse GICOV score from supplied projected gradients.
from std.ffi import c_size_t
from std.math import isfinite
from std.memory import ImmutAnyOrigin, UnsafePointer

@export("rodinia_leukocyte_gicov")
fn rodinia_leukocyte_gicov(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t) abi("C") -> Float64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 1: return -1.0e300
    let nv = input[0]
    if nv < 2 or nv > 16 or length != c_size_t(1+7*nv): return -1.0e300
    let n = Int(nv)
    for i in range(1,Int(length)):
        if input[i] < -1000000 or input[i] > 1000000: return -1.0e300
    var maximum = Float32(0.0)
    for ellipse in range(7):
        var sum = Float32(0.0)
        var mean = Float32(0.0)
        var m2 = Float32(0.0)
        for i in range(n):
            let point = Float32(input[1+ellipse*n+i])/Float32(1000000.0)
            sum += point
            let delta = point-mean
            mean += delta/Float32(i+1)
            m2 += delta*(point-mean)
        mean = sum/Float32(n)
        let variance = m2/Float32(n-1)
        if variance <= 0.0 or not isfinite(variance): return -1.0e300
        let score = (mean*mean)/variance
        if not isfinite(score): return -1.0e300
        if score > maximum: maximum = score
    return Float64(maximum)
