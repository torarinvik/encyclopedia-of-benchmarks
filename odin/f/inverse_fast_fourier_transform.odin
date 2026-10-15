package inverse_fast_fourier_transform

import "core:c"
import "core:math"

store_i64_le :: proc "contextless" (output: [^]u8, offset: int, value: i64) {
    bits := u64(value)
    for byte := 0; byte < 8; byte += 1 { output[offset + byte] = u8((bits >> u64(byte * 8)) & 255) }
}
quantize :: proc "contextless" (value: f64) -> i64 {
    scaled := value * 1_000_000.0
    if scaled >= 0 do return i64(scaled + 0.5)
    return i64(scaled - 0.5)
}
transform :: proc "contextless" (real, imag: [^]f64, n: int) {
    reverse := 0
    for position := 1; position < n; position += 1 {
        bit := n >> 1
        for (reverse & bit) != 0 { reverse ^= bit; bit >>= 1 }
        reverse ^= bit
        if position < reverse { temporary := real[position]; real[position] = real[reverse]; real[reverse] = temporary; temporary = imag[position]; imag[position] = imag[reverse]; imag[reverse] = temporary }
    }
    block := 2
    for block <= n {
        angle := 6.283185307179586476925286766559 / f64(block)
        step_real, step_imag := math.cos(angle), -math.sin(angle)
        for start := 0; start < n; start += block {
            weight_real, weight_imag := 1.0, 0.0
            for offset := 0; offset < block / 2; offset += 1 {
                first, second := start + offset, start + offset + block / 2
                product_real := weight_real * real[second] - weight_imag * imag[second]
                product_imag := weight_real * imag[second] + weight_imag * real[second]
                first_real, first_imag := real[first], imag[first]
                real[first], imag[first] = first_real + product_real, first_imag + product_imag
                real[second], imag[second] = first_real - product_real, first_imag - product_imag
                next_real := weight_real * step_real - weight_imag * step_imag
                weight_imag = weight_real * step_imag + weight_imag * step_real
                weight_real = next_real
            }
        }
        block *= 2
    }
}

@(export)
inverse_fast_fourier_transform :: proc "c" (values: [^]i64, length: c.size_t, output: [^]u8, output_capacity: c.size_t) -> i64 {
    if values == nil || length < 3 || length > 129 do return -1
    raw_n := values[0]
    if raw_n < 1 || raw_n > 64 || (raw_n & (raw_n - 1)) != 0 do return -1
    n := int(raw_n)
    if length != c.size_t(1 + 2 * n) do return -1
    for index := 0; index < 2 * n; index += 1 { if values[index + 1] < -1000 || values[index + 1] > 1000 do return -1 }
    byte_count := 8 * n
    if output == nil || output_capacity < c.size_t(byte_count) do return -2
    real: [64]f64
    imag: [64]f64
    for index := 0; index < n; index += 1 { real[index] = f64(values[index * 2 + 1]); imag[index] = f64(values[index * 2 + 2]) }
    transform(&real[0], &imag[0], n)
    for index := 0; index < n; index += 1 { store_i64_le(output, index * 8, quantize(real[index] / f64(n))) }
    return i64(byte_count)
}
