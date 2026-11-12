from std.collections import InlineArray
from std.ffi import c_size_t
from std.math import cos, isfinite, sin, sqrt, trunc
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

comptime MAX_N = 64
comptime MAX_STEPS = 8
comptime MAX_INPUT_LENGTH = 2 + 4 * MAX_N
comptime TAU = 6.28318530717958647692528676655900577

fn bounded_integer(value: Float64, minimum: Float64, maximum: Float64) -> Bool:
    return isfinite(value) and value >= minimum and value <= maximum and trunc(value) == value

fn fft(inout real: InlineArray[Float64, MAX_N], inout imag: InlineArray[Float64, MAX_N],
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

fn normalize(inout real: InlineArray[Float64, MAX_N],
             inout imag: InlineArray[Float64, MAX_N], n: Int):
    var norm_squared: Float64 = 0.0
    for i in range(n): norm_squared += real[i] * real[i] + imag[i] * imag[i]
    let norm = sqrt(norm_squared)
    for i in range(n):
        real[i] /= norm
        imag[i] /= norm

@export("split_operator_imaginary_time")
fn split_operator_imaginary_time(
    input: UnsafePointer[Float64, ImmutAnyOrigin], length: c_size_t,
    output: UnsafePointer[Float64, MutAnyOrigin], capacity: c_size_t
) abi("C") -> Int64:
    if input == UnsafePointer[Float64, ImmutAnyOrigin]() or length < 2 or length > MAX_INPUT_LENGTH:
        return -1
    if not bounded_integer(input[0], 2.0, Float64(MAX_N))
        or not bounded_integer(input[1], 0.0, Float64(MAX_STEPS)):
        return -1
    let n = Int(input[0])
    let steps = Int(input[1])
    if (n & (n - 1)) != 0 or length != c_size_t(2 + 4 * n): return -1
    let momentum_start = 2 + n
    let state_start = 2 + 2 * n
    var norm_squared: Float64 = 0.0
    for i in range(n):
        let position = input[2 + i]
        let momentum = input[momentum_start + i]
        let real_value = input[state_start + 2 * i]
        let imag_value = input[state_start + 2 * i + 1]
        if not isfinite(position) or position < 0.25 or position > 1.0
            or not isfinite(momentum) or momentum < 0.25 or momentum > 1.0
            or not isfinite(real_value) or real_value < -1.0 or real_value > 1.0
            or not isfinite(imag_value) or imag_value < -1.0 or imag_value > 1.0:
            return -1
        norm_squared += real_value * real_value + imag_value * imag_value
    if not norm_squared > 0.0: return -1
    let output_count = 2 * n
    if output == UnsafePointer[Float64, MutAnyOrigin]() or capacity < c_size_t(output_count):
        return -2

    var real = InlineArray[Float64, MAX_N]()
    var imag = InlineArray[Float64, MAX_N]()
    for i in range(n):
        real[i] = input[state_start + 2 * i]
        imag[i] = input[state_start + 2 * i + 1]
    normalize(real, imag, n)
    for _ in range(steps):
        for i in range(n):
            real[i] *= input[2 + i]
            imag[i] *= input[2 + i]
        fft(real, imag, n, False)
        for i in range(n):
            real[i] *= input[momentum_start + i]
            imag[i] *= input[momentum_start + i]
        fft(real, imag, n, True)
        for i in range(n):
            real[i] *= input[2 + i]
            imag[i] *= input[2 + i]
        normalize(real, imag, n)
    for i in range(n):
        output[2 * i] = real[i]
        output[2 * i + 1] = imag[i]
    return Int64(output_count)
