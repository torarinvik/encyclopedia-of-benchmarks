from std.collections import InlineArray
from std.ffi import c_size_t
from std.math import cos, isfinite, sin
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

fn rader_fft8(inout real: InlineArray[Float64, 8], inout imag: InlineArray[Float64, 8], inverse: Bool):
    for i in range(8):
        let j = ((i & 1) << 2) | (i & 2) | ((i & 4) >> 2)
        if i < j:
            let r = real[i]
            let v = imag[i]
            real[i] = real[j]
            imag[i] = imag[j]
            real[j] = r
            imag[j] = v
    var block = 2
    while block <= 8:
        let half = block // 2
        var start = 0
        while start < 8:
            for j in range(half):
                var angle = 6.283185307179586476925286766559 * Float64(j) / Float64(block)
                if not inverse: angle = -angle
                let wr = cos(angle)
                let wi = sin(angle)
                let even = start + j
                let odd = even + half
                let ur = real[even]
                let ui = imag[even]
                let vr = real[odd] * wr - imag[odd] * wi
                let vi = real[odd] * wi + imag[odd] * wr
                real[even] = ur + vr
                imag[even] = ui + vi
                real[odd] = ur - vr
                imag[odd] = ui - vi
            start += block
        block *= 2
    if inverse:
        for i in range(8):
            real[i] /= 8.0
            imag[i] /= 8.0

@export("rader_fft")
fn rader_fft(input: UnsafePointer[Float64, ImmutAnyOrigin], length: c_size_t,
             output: UnsafePointer[Float64, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Float64, ImmutAnyOrigin]() or length != 10: return -1
    for i in range(10):
        if not isfinite(input[i]) or input[i] < -100.0 or input[i] > 100.0: return -1
    if output == UnsafePointer[Float64, MutAnyOrigin]() or capacity < 10: return -2
    var permutation = InlineArray[Int, 4](fill=0)
    var inverse_powers = InlineArray[Int, 4](fill=0)
    permutation[0] = 1
    permutation[1] = 2
    permutation[2] = 4
    permutation[3] = 3
    inverse_powers[0] = 1
    inverse_powers[1] = 3
    inverse_powers[2] = 4
    inverse_powers[3] = 2
    var ar = InlineArray[Float64, 8](fill=0.0)
    var ai = InlineArray[Float64, 8](fill=0.0)
    var br = InlineArray[Float64, 8](fill=0.0)
    var bi = InlineArray[Float64, 8](fill=0.0)
    for i in range(4):
        ar[i] = input[2 * permutation[i]]
        ai[i] = input[2 * permutation[i] + 1]
        let angle = -6.283185307179586476925286766559 * Float64(inverse_powers[i]) / 5.0
        br[i] = cos(angle)
        bi[i] = sin(angle)
    rader_fft8(ar, ai, False)
    rader_fft8(br, bi, False)
    for i in range(8):
        let real = ar[i] * br[i] - ai[i] * bi[i]
        let imag = ar[i] * bi[i] + ai[i] * br[i]
        ar[i] = real
        ai[i] = imag
    rader_fft8(ar, ai, True)
    var result = InlineArray[Float64, 10](fill=0.0)
    for i in range(5):
        result[0] += input[2 * i]
        result[1] += input[2 * i + 1]
    for i in range(1, 5):
        result[2 * i] = input[0]
        result[2 * i + 1] = input[1]
    for i in range(4):
        let target = inverse_powers[i]
        result[2 * target] += ar[i] + ar[i + 4]
        result[2 * target + 1] += ai[i] + ai[i + 4]
    for i in range(10): output[i] = result[i]
    return 10
