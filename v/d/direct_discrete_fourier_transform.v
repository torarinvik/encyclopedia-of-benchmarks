import math

const max_n = 64
const max_input_length = 130
const tau = 6.283185307179586476925286766559

@[export: 'direct_discrete_fourier_transform']
pub fn direct_discrete_fourier_transform(input &f64, input_length usize, mut output &f64, output_capacity usize) i64 {
    unsafe {
        if input == nil || input_length < 2 || input_length > max_input_length { return -1 }
        for i in 0 .. input_length { if !math.is_finite(input[i]) { return -1 } }
        n_value := input[0]
        if n_value < 1.0 || n_value > f64(max_n) || math.trunc(n_value) != n_value { return -1 }
        n := int(n_value)
        if input_length != usize(1 + 2 * n) { return -1 }
        for i in 0 .. 2 * n {
            if input[i + 1] < -8.0 || input[i + 1] > 8.0 { return -1 }
        }

        needed := 2 * n
        if output == nil || output_capacity < usize(needed) { return -2 }
        for k in 0 .. n {
            mut real_sum := 0.0
            mut imag_sum := 0.0
            for j in 0 .. n {
                angle := -tau * f64(j) * f64(k) / f64(n)
                cosine := math.cos(angle)
                sine := math.sin(angle)
                sample_real := input[1 + 2 * j]
                sample_imag := input[2 + 2 * j]
                real_sum += sample_real * cosine + sample_imag * sine
                imag_sum += sample_imag * cosine - sample_real * sine
            }
            output[2 * k] = real_sum
            output[2 * k + 1] = imag_sum
        }
        return i64(needed)
    }
}

