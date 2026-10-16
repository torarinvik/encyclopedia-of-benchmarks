package gabor_filter

import "core:c"
import "core:math"

PI :: 3.14159265358979323846264338327950288

put_f32_le :: proc(output: [^]u8, offset: int, value: f64) {
    rounded := f32(value)
    bits := transmute(u32)rounded
    for byte := 0; byte < 4; byte += 1 {
        output[offset + byte] = u8(bits >> u32(8 * byte))
    }
}

@(export)
gabor_filter :: proc "c"(values: [^]i64, length: c.size_t,
                          output: [^]u8, capacity: c.size_t) -> i64 {
    if values == nil || length < 1 || length > 7 do return -1
    if length != 6 do return -1
    requested, sigma, theta := values[0], values[1], values[2]
    wavelength, gamma, phase := values[3], values[4], values[5]
    if requested < 1 || requested > 7 || sigma < 1 || sigma > 8 do return -1
    if theta < 0 || theta > 359 || wavelength < 1 || wavelength > 8 do return -1
    if gamma < 0 || gamma > 4 || phase < -6 || phase > 6 do return -1

    side := int(requested)
    if side % 2 == 0 do side += 1
    output_bytes := side * side * 4
    if output == nil || capacity < c.size_t(output_bytes) do return -2

    angle := (f64(theta) / 180.0) * PI
    cosine, sine := math.cos_f64(angle), math.sin_f64(angle)
    center := side / 2
    offset := 0
    for y := 0; y < side; y += 1 {
        py := f64(y - center)
        for x := 0; x < side; x += 1 {
            px := f64(x - center)
            kernel_x := cosine * px + sine * py
            kernel_y := -sine * px + cosine * py
            exponent := -(kernel_x * kernel_x + f64(gamma * gamma) * kernel_y * kernel_y) /
                (2.0 * f64(sigma) * f64(sigma))
            phase_angle := 2.0 * PI * kernel_x / f64(wavelength) + f64(phase)
            put_f32_le(output, offset, math.exp_f64(exponent) * math.cos_f64(phase_angle))
            offset += 4
        }
    }
    i64(output_bytes)
}
