from std.collections import InlineArray
from std.ffi import c_size_t
from std.math import ceil, cos, floor, sin
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

fn bluestein_fft(inout real: InlineArray[Float64, 32], inout imag: InlineArray[Float64, 32], n: Int64, inverse: Bool):
    var j: Int64 = 0
    for i in range(1, n):
        var bit = n >> 1
        while (j & bit) != 0:
            j ^= bit
            bit >>= 1
        j ^= bit
        if i < j:
            let tr = real[i]; real[i] = real[j]; real[j] = tr
            let ti = imag[i]; imag[i] = imag[j]; imag[j] = ti
    var block: Int64 = 2
    while block <= n:
        let sign = 1.0 if inverse else -1.0
        let angle = sign * 6.2831853071795864769 / Float64(block)
        let cr = cos(angle)
        let ci = sin(angle)
        var start: Int64 = 0
        while start < n:
            var wr = 1.0
            var wi = 0.0
            for k in range(block / 2):
                let u = start + k
                let v = u + block / 2
                let pr = wr * real[v] - wi * imag[v]
                let pi = wr * imag[v] + wi * real[v]
                let ur = real[u]
                let ui = imag[u]
                real[u] = ur + pr
                imag[u] = ui + pi
                real[v] = ur - pr
                imag[v] = ui - pi
                let nr = wr * cr - wi * ci
                wi = wr * ci + wi * cr
                wr = nr
            start += block
        block *= 2
    if inverse:
        for i in range(n):
            real[i] /= Float64(n)
            imag[i] /= Float64(n)

fn bluestein_quant(x: Float64) -> Int64:
    let scaled = x * 1000000.0
    return Int64(floor(scaled + 0.5)) if scaled >= 0.0 else Int64(ceil(scaled - 0.5))

@export("fft_bluestein")
fn fft_bluestein(v: UnsafePointer[Int64, ImmutAnyOrigin], n_input: c_size_t, output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if v == UnsafePointer[Int64, ImmutAnyOrigin]() or n_input < 2 or n_input > 9: return -1
    let m = v[0]
    if m < 1 or m > 8 or n_input != m + 1: return -1
    for i in range(m):
        if v[i + 1] < -8 or v[i + 1] > 8: return -1
    var z: Int64 = 1
    let needed = 3 * m - 2
    while z < needed: z *= 2
    let bytes = m * 16
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < bytes: return -2
    var ar = InlineArray[Float64, 32](0.0)
    var ai = InlineArray[Float64, 32](0.0)
    var br = InlineArray[Float64, 32](0.0)
    var bi = InlineArray[Float64, 32](0.0)
    let pi = 3.14159265358979323846
    for j in range(m):
        let angle = -pi * Float64(j) * Float64(j) / Float64(m)
        ar[j] = Float64(v[j + 1]) * cos(angle)
        ai[j] = Float64(v[j + 1]) * sin(angle)
    for k in range(-(m - 1), m):
        let angle = pi * Float64(k) * Float64(k) / Float64(m)
        let ix = k + m - 1
        br[ix] = cos(angle)
        bi[ix] = sin(angle)
    bluestein_fft(ar, ai, z, False)
    bluestein_fft(br, bi, z, False)
    for i in range(z):
        let x = ar[i] * br[i] - ai[i] * bi[i]
        ai[i] = ar[i] * bi[i] + ai[i] * br[i]
        ar[i] = x
    bluestein_fft(ar, ai, z, True)
    var stage = InlineArray[Int64, 16](0)
    for k in range(m):
        let angle = -pi * Float64(k) * Float64(k) / Float64(m)
        let cr = cos(angle)
        let ci = sin(angle)
        let re = ar[k + m - 1] * cr - ai[k + m - 1] * ci
        let im = ar[k + m - 1] * ci + ai[k + m - 1] * cr
        stage[2 * k] = bluestein_quant(re)
        stage[2 * k + 1] = bluestein_quant(im)
    for i in range(2 * m):
        let bits = UInt64(stage[i])
        for b in range(8): output[i * 8 + b] = UInt8((bits >> (8 * b)) & 255)
    return bytes
