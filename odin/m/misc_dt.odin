package misc_dt

import "core:c"
import "core:math"

MAX_ITERATIONS :: 128
MAX_VECTOR_SIZE :: 64

@(export, link_name="misc_dt")
misc_dt :: proc "c" (input: [^]f64, input_length: c.size_t,
    output: [^]f64, output_capacity: c.size_t) -> i64 {
    if input == nil || input_length != c.size_t(2) do return -1
    requested_iterations := input[0]
    requested_size := input[1]
    if !(requested_iterations >= 1.0 && requested_iterations <= f64(MAX_ITERATIONS)) ||
        requested_iterations != f64(i64(requested_iterations)) do return -1
    if !(requested_size >= 1.0 && requested_size <= f64(MAX_VECTOR_SIZE)) ||
        requested_size != f64(int(requested_size)) do return -1
    iterations := i64(requested_iterations)
    size := int(requested_size)
    if output == nil || output_capacity < c.size_t(size) do return -2

    numerator: [MAX_VECTOR_SIZE]f64
    denominator: [MAX_VECTOR_SIZE]f64
    for index := 0; index < size; index += 1 {
        cosine := f32(math.cos(f64(size-index)))
        sine := f32(math.sin(f64(index)))
        numerator[index] = 1.0000001 * f64(cosine)
        denominator[index] = 1.0 + 1e-10 * f64(sine)
    }
    for _iteration := i64(0); _iteration < iterations; _iteration += 1 {
        for index := 0; index < size; index += 1 do numerator[index] /= denominator[index]
    }
    for index := 0; index < size; index += 1 do output[index] = numerator[index]
    return i64(size)
}
