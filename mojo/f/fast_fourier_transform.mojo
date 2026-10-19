from std.collections import InlineArray
from std.ffi import c_size_t
from std.math import cos, sin
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

@export("fast_fourier_transform")
fn fast_fourier_transform(values: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t, output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if values == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 2 or length > 65: return -1
    let n = values[0]
    if n < 1 or n > 64 or (n & (n - 1)) != 0 or length != n + 1: return -1
    var real = InlineArray[Float64, 64](0.0)
    var imag = InlineArray[Float64, 64](0.0)
    for i in range(n):
        if values[i + 1] < -1000 or values[i + 1] > 1000: return -1
        real[i] = Float64(values[i + 1])
    let bytes = 16 * n
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < bytes: return -2
    var rev: Int64 = 0
    for pos in range(1, n):
        var bit = n >> 1
        while (rev & bit) != 0:
            rev ^= bit
            bit >>= 1
        rev ^= bit
        if pos < rev:
            let tr = real[pos]
            real[pos] = real[rev]
            real[rev] = tr
            let ti = imag[pos]
            imag[pos] = imag[rev]
            imag[rev] = ti
    var block: Int64 = 2
    while block <= n:
        let angle = 6.283185307179586476925286766559 / Float64(block)
        let sr = cos(angle)
        let si = sin(angle)
        var start: Int64 = 0
        while start < n:
            var wr = 1.0
            var wi = 0.0
            for off in range(block / 2):
                let first = start + off
                let second = first + block / 2
                let pr = wr * real[second] - wi * imag[second]
                let pi = wr * imag[second] + wi * real[second]
                let fr = real[first]
                let fi = imag[first]
                real[first] = fr + pr
                imag[first] = fi + pi
                real[second] = fr - pr
                imag[second] = fi - pi
                let nr = wr * sr - wi * si
                wi = wr * si + wi * sr
                wr = nr
            start += block
        block *= 2
    var stage = InlineArray[Int64, 128](0)
    for i in range(n):
        let sr = real[i] * 1000000.0
        let si = imag[i] * 1000000.0
        stage[2 * i] = Int64(sr + 0.5 if sr >= 0.0 else sr - 0.5)
        stage[2 * i + 1] = Int64(si + 0.5 if si >= 0.0 else si - 0.5)
    for i in range(2 * n):
        let bits = UInt64(stage[i])
        for b in range(8): output[i * 8 + b] = UInt8((bits >> (8 * b)) & 255)
    return bytes
