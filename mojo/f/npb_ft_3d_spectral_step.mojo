from std.collections import InlineArray
from std.ffi import c_size_t
from std.math import cos, exp, isfinite, sin, trunc
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

comptime MAX_POINTS = 64
comptime MAX_STEPS = 6
comptime CHECKSUM_TERMS = 64
comptime TAU = 6.28318530717958647692528676655900577
comptime ALPHA = 0.000001

fn fft_line(inout real: InlineArray[Float64, 4], inout imag: InlineArray[Float64, 4],
            n: Int, inverse: Bool):
    var reverse = 0
    for position in range(1, n):
        var bit = n >> 1
        while bit != 0 and (reverse & bit) != 0:
            reverse ^= bit
            bit >>= 1
        reverse ^= bit
        if position < reverse:
            let temp_real = real[position]
            real[position] = real[reverse]
            real[reverse] = temp_real
            let temp_imag = imag[position]
            imag[position] = imag[reverse]
            imag[reverse] = temp_imag
    var block = 2
    while block <= n:
        let direction = 1.0 if inverse else -1.0
        let angle = direction * TAU / Float64(block)
        let step_real = cos(angle)
        let step_imag = sin(angle)
        for start in range(0, n, block):
            var weight_real: Float64 = 1.0
            var weight_imag: Float64 = 0.0
            for offset in range(block // 2):
                let first = start + offset
                let second = first + block // 2
                let product_real = weight_real * real[second] - weight_imag * imag[second]
                let product_imag = weight_real * imag[second] + weight_imag * real[second]
                let first_real = real[first]
                let first_imag = imag[first]
                real[first] = first_real + product_real
                imag[first] = first_imag + product_imag
                real[second] = first_real - product_real
                imag[second] = first_imag - product_imag
                let next_real = weight_real * step_real - weight_imag * step_imag
                weight_imag = weight_real * step_imag + weight_imag * step_real
                weight_real = next_real
        block *= 2
    if inverse:
        for i in range(n):
            real[i] /= Float64(n)
            imag[i] /= Float64(n)

fn line_index(axis: Int, a: Int, b: Int, p: Int, n: Int) -> Int:
    if axis == 0:
        return (p * n + a) * n + b
    if axis == 1:
        return (a * n + p) * n + b
    return (a * n + b) * n + p

fn axis_transform(inout real: InlineArray[Float64, MAX_POINTS],
                  inout imag: InlineArray[Float64, MAX_POINTS],
                  n: Int, axis: Int, inverse: Bool):
    for a in range(n):
        for b in range(n):
            var line_real = InlineArray[Float64, 4]()
            var line_imag = InlineArray[Float64, 4]()
            for p in range(n):
                let index = line_index(axis, a, b, p, n)
                line_real[p] = real[index]
                line_imag[p] = imag[index]
            fft_line(line_real, line_imag, n, inverse)
            for p in range(n):
                let index = line_index(axis, a, b, p, n)
                real[index] = line_real[p]
                imag[index] = line_imag[p]

fn transform3d(inout real: InlineArray[Float64, MAX_POINTS],
               inout imag: InlineArray[Float64, MAX_POINTS], n: Int, inverse: Bool):
    axis_transform(real, imag, n, 2, inverse)
    axis_transform(real, imag, n, 1, inverse)
    axis_transform(real, imag, n, 0, inverse)

fn signed_frequency(index: Int, n: Int) -> Int:
    if index <= n // 2:
        return index
    return index - n

@export("npb_ft_3d_spectral_step")
fn npb_ft_3d_spectral_step(input: UnsafePointer[Float64, ImmutAnyOrigin],
    input_length: c_size_t, output: UnsafePointer[Float64, MutAnyOrigin],
    output_capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Float64, ImmutAnyOrigin]() or input_length < 2 or input_length > 130:
        return -1
    if input[0] != 2.0 and input[0] != 4.0:
        return -1
    if not isfinite(input[1]) or input[1] < 1.0 or input[1] > Float64(MAX_STEPS) or trunc(input[1]) != input[1]:
        return -1
    let n = Int(input[0])
    let steps = Int(input[1])
    let volume = n * n * n
    if input_length != c_size_t(2 + 2 * volume):
        return -1
    for i in range(2, Int(input_length)):
        if not isfinite(input[i]) or input[i] < -1.0 or input[i] > 1.0:
            return -1
    let needed = 2 * steps
    if output == UnsafePointer[Float64, MutAnyOrigin]() or output_capacity < c_size_t(needed):
        return -2

    var spectrum_real = InlineArray[Float64, MAX_POINTS]()
    var spectrum_imag = InlineArray[Float64, MAX_POINTS]()
    var work_real = InlineArray[Float64, MAX_POINTS]()
    var work_imag = InlineArray[Float64, MAX_POINTS]()
    for i in range(volume):
        spectrum_real[i] = input[2 + 2 * i]
        spectrum_imag[i] = input[2 + 2 * i + 1]
    transform3d(spectrum_real, spectrum_imag, n, False)
    for step in range(1, steps + 1):
        for x in range(n):
            for y in range(n):
                for z in range(n):
                    let index = (x * n + y) * n + z
                    let kx = signed_frequency(x, n)
                    let ky = signed_frequency(y, n)
                    let kz = signed_frequency(z, n)
                    let radius_squared = Float64(kx * kx + ky * ky + kz * kz)
                    let factor = exp(-39.47841760435743447533796399950460 * ALPHA * Float64(step) * radius_squared)
                    work_real[index] = spectrum_real[index] * factor
                    work_imag[index] = spectrum_imag[index] * factor
        transform3d(work_real, work_imag, n, True)
        var sum_real: Float64 = 0.0
        var sum_imag: Float64 = 0.0
        for j in range(1, CHECKSUM_TERMS + 1):
            let x = (j - 1) % n
            let y = (3 * j - 1) % n
            let z = (5 * j - 1) % n
            let index = (x * n + y) * n + z
            sum_real += work_real[index]
            sum_imag += work_imag[index]
        output[2 * (step - 1)] = sum_real / Float64(volume)
        output[2 * (step - 1) + 1] = sum_imag / Float64(volume)
    Int64(needed)
