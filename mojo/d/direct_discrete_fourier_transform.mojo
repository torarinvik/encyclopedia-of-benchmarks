from std.ffi import c_size_t
from std.math import cos, sin, isfinite
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

@export("direct_discrete_fourier_transform")
fn direct_discrete_fourier_transform(
    input: UnsafePointer[Float64, ImmutAnyOrigin], input_length: c_size_t,
    output: UnsafePointer[Float64, MutAnyOrigin], output_capacity: c_size_t,
) abi("C") -> Int64:
    if input == UnsafePointer[Float64, ImmutAnyOrigin]() or input_length < 2 or input_length > 130:
        return -1
    for i in range(input_length):
        if not isfinite(input[i]):
            return -1
    let n_value = input[0]
    if n_value < 1.0 or n_value > 64.0:
        return -1
    let n = Int(n_value)
    if Float64(n) != n_value or input_length != c_size_t(1 + 2 * n):
        return -1
    for i in range(2 * n):
        if input[i + 1] < -8.0 or input[i + 1] > 8.0:
            return -1

    let needed = 2 * n
    if output == UnsafePointer[Float64, MutAnyOrigin]() or output_capacity < c_size_t(needed):
        return -2
    for k in range(n):
        var real_sum = 0.0
        var imag_sum = 0.0
        for j in range(n):
            let angle = -6.283185307179586476925286766559 * Float64(j) * Float64(k) / Float64(n)
            let cosine = cos(angle)
            let sine = sin(angle)
            let sample_real = input[1 + 2 * j]
            let sample_imag = input[2 + 2 * j]
            real_sum += sample_real * cosine + sample_imag * sine
            imag_sum += sample_imag * cosine - sample_real * sine
        output[2 * k] = real_sum
        output[2 * k + 1] = imag_sum
    return Int64(needed)
}

