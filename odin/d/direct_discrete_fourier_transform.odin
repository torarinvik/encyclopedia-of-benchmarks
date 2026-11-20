package direct_discrete_fourier_transform

import "core:c"
import "core:math"

TAU :: 6.283185307179586476925286766559

@(export)
direct_discrete_fourier_transform :: proc "c" (input: [^]f64, input_length: c.size_t,
    output: [^]f64, output_capacity: c.size_t) -> i64 {
    if input == nil || input_length < 2 || input_length > 130 do return -1
    for i in 0..<int(input_length) { if !math.is_finite(input[i]) do return -1 }
    n_value := input[0]
    if n_value < 1 || n_value > 64 || math.trunc(n_value) != n_value do return -1
    n := int(n_value)
    if input_length != c.size_t(1+2*n) do return -1
    for i in 0..<2*n { if input[i+1] < -8 || input[i+1] > 8 do return -1 }

    needed := 2*n
    if output == nil || output_capacity < c.size_t(needed) do return -2
    for k in 0..<n {
        real_sum := 0.0
        imag_sum := 0.0
        for j in 0..<n {
            angle := -TAU*f64(j)*f64(k)/f64(n)
            cosine, sine := math.cos_f64(angle), math.sin_f64(angle)
            sample_real, sample_imag := input[1+2*j], input[2+2*j]
            real_sum += sample_real*cosine + sample_imag*sine
            imag_sum += sample_imag*cosine - sample_real*sine
        }
        output[2*k] = real_sum
        output[2*k+1] = imag_sum
    }
    return i64(needed)
}

