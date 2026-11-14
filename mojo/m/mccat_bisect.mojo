# Bounded independent implementation; see the McGill/McCAT notice in the package README.
from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

comptime BISECT_EPS = 2.2204460492503131e-16

fn mccat_sturm(diagonal: InlineArray[Float64, 32], off: InlineArray[Float64, 32],
               beta: InlineArray[Float64, 32], n: Int, x: Float64) -> Int:
    var count = 0
    var q: Float64 = 1.0
    for i in range(n):
        if q != 0.0: q = (diagonal[i] - x) - beta[i] / q
        else: q = (diagonal[i] - x) - abs(off[i]) / BISECT_EPS
        if q < 0.0: count += 1
    return count

@export("mccat_bisect")
fn mccat_bisect(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
                output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length != 1: return -1
    if input[0] < 2 or input[0] > 32: return -1
    let n = Int(input[0])
    let bytes = 8 * (n + 1)
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(bytes): return -2
    var diagonal = InlineArray[Float64, 32](fill=0.0)
    var off = InlineArray[Float64, 32](fill=0.0)
    var beta = InlineArray[Float64, 32](fill=0.0)
    var eigen = InlineArray[Float64, 33](fill=0.0)
    var lower = InlineArray[Float64, 33](fill=0.0)
    for i in range(n):
        let value = Float64(i + 1)
        diagonal[i] = value * value
        diagonal[i] *= diagonal[i]
        off[i] = Float64(i)
        beta[i] = off[i] * off[i]
    var xmin = diagonal[n - 1] - 1.01 * abs(off[n - 1])
    var xmax = diagonal[n - 1] + 1.01 * abs(off[n - 1])
    var i = n - 1
    while i > 0:
        i -= 1
        let h = 1.01 * (abs(off[i]) + abs(off[i + 1]))
        if diagonal[i] + h > xmax: xmax = diagonal[i] + h
        if diagonal[i] - h < xmin: xmin = diagonal[i] - h
    let scale = if xmin + xmax > 0.0: xmax else: -xmin
    var eps2 = BISECT_EPS * scale
    eps2 = 0.5 * BISECT_EPS + 7.0 * eps2
    var x0 = xmax
    for index in range(1, n + 1):
        eigen[index] = xmax
        lower[index] = xmin
    var iterations = 0
    var k = n
    while k > 0:
        var xu = xmin
        var index = k
        while index > 0:
            if xu < lower[index]:
                xu = lower[index]
                break
            index -= 1
        if x0 > eigen[k]: x0 = eigen[k]
        var x1 = (xu + x0) / 2.0
        while x0 - xu > 2.0 * BISECT_EPS * (abs(xu) + abs(x0)) + BISECT_EPS:
            iterations += 1
            let count = mccat_sturm(diagonal, off, beta, n, x1)
            if count < k:
                xu = x1
                if count < 1: lower[1] = x1
                else:
                    lower[count + 1] = x1
                    if eigen[count] > x1: eigen[count] = x1
            else: x0 = x1
            x1 = (xu + x0) / 2.0
        eigen[k] = (xu + x0) / 2.0
        k -= 1
    for word in range(n + 1):
        var value: Float64 = 0.0
        if word < n - 1: value = eigen[word + 2]
        elif word == n - 1: value = eps2
        else: value = Float64(iterations)
        var bits = bitcast[UInt64](value)
        for b in range(8):
            output[8 * word + b] = UInt8(bits & 255)
            bits >>= 8
    return Int64(bytes)
