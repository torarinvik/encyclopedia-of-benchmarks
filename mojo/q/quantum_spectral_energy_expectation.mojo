from std.collections import InlineArray
from std.ffi import c_size_t
from std.math import cos, sin
from std.memory import ImmutAnyOrigin, UnsafePointer

comptime MAX_N = 32
comptime SCALE: Int64 = 256
comptime INVALID_RESULT: Float64 = -1e300
comptime TAU: Float64 = 6.283185307179586476925286766559005768

fn quantum_spectral_fft(inout real: InlineArray[Float64, 32],
                        inout imag: InlineArray[Float64, 32], n: Int64,
                        inverse: Bool):
    var reverse: Int64 = 0
    for position in range(1, n):
        var bit = n >> 1
        while (reverse & bit) != 0:
            reverse ^= bit
            bit >>= 1
        reverse ^= bit
        if position < reverse:
            let temporary_real = real[position]
            real[position] = real[reverse]
            real[reverse] = temporary_real
            let temporary_imag = imag[position]
            imag[position] = imag[reverse]
            imag[reverse] = temporary_imag
    var block: Int64 = 2
    while block <= n:
        let direction = 1.0 if inverse else -1.0
        let angle = direction * TAU / Float64(block)
        let step_real = cos(angle)
        let step_imag = sin(angle)
        var start: Int64 = 0
        while start < n:
            var weight_real = 1.0
            var weight_imag = 0.0
            for offset in range(block / 2):
                let first = start + offset
                let second = first + block / 2
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
            start += block
        block *= 2
    if inverse:
        for index in range(n):
            real[index] /= Float64(n)
            imag[index] /= Float64(n)

@export("quantum_spectral_energy_expectation")
fn quantum_spectral_energy_expectation(values: UnsafePointer[Int64, ImmutAnyOrigin],
                                      length: c_size_t) abi("C") -> Float64:
    if values == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 1 or length > 98:
        return INVALID_RESULT
    let n_value = values[0]
    if n_value < 2 or n_value > MAX_N or (n_value & (n_value - 1)) != 0:
        return INVALID_RESULT
    if Int64(length) != 1 + 3 * n_value:
        return INVALID_RESULT
    let n = n_value
    var norm: Int64 = 0
    for index in range(n):
        let potential = values[1 + index]
        let real_q = values[1 + n + index]
        let imag_q = values[1 + 2 * n + index]
        if potential < -2048 or potential > 2048 or real_q < -2048 or real_q > 2048 or
           imag_q < -2048 or imag_q > 2048:
            return INVALID_RESULT
        norm += real_q * real_q + imag_q * imag_q
    if norm != SCALE * SCALE * n:
        return INVALID_RESULT

    var real = InlineArray[Float64, 32](0.0)
    var imag = InlineArray[Float64, 32](0.0)
    for index in range(n):
        real[index] = Float64(values[1 + n + index]) / Float64(SCALE)
        imag[index] = Float64(values[1 + 2 * n + index]) / Float64(SCALE)
    quantum_spectral_fft(real, imag, n, False)
    for index in range(n):
        let frequency = index if index <= n / 2 else index - n
        let wave_number = TAU * Float64(frequency)
        let multiplier = 0.5 * wave_number * wave_number
        real[index] *= multiplier
        imag[index] *= multiplier
    quantum_spectral_fft(real, imag, n, True)

    var total = 0.0
    for index in range(n):
        let psi_real = Float64(values[1 + n + index]) / Float64(SCALE)
        let psi_imag = Float64(values[1 + 2 * n + index]) / Float64(SCALE)
        let potential = Float64(values[1 + index]) / Float64(SCALE)
        total += psi_real * (real[index] + potential * psi_real)
            + psi_imag * (imag[index] + potential * psi_imag)
    return total / Float64(n)
