package vector_cross_product

import "core:c"
import "core:math"

store_i64_le :: proc "c" (output: [^]u8, offset: int, value: i64) {
    bits := u64(value)
    for byte := 0; byte < 8; byte += 1 {
        output[offset + byte] = u8(bits & 255)
        bits >>= 8
    }
}

// Cross two bounded integer vectors and encode components plus magnitude.
@(export)
vector_cross_product :: proc "c" (input: [^]i64, input_length: c.size_t,
        output: [^]u8, output_capacity: c.size_t) -> i64 {
    if input == nil || input_length != 6 do return -1
    for index := 0; index < 6; index += 1 {
        if input[index] < -1_000_000 || input[index] > 1_000_000 do return -1
    }
    x := input[1] * input[5] - input[2] * input[4]
    y := -((input[0] * input[5]) - (input[2] * input[3]))
    z := input[0] * input[4] - input[1] * input[3]
    magnitude := math.sqrt(f64(x) * f64(x) + f64(y) * f64(y) + f64(z) * f64(z))
    magnitude_micro := i64(magnitude * 1_000_000.0 + 0.5)
    if output == nil || output_capacity < 32 do return -2
    store_i64_le(output, 0, x); store_i64_le(output, 8, y)
    store_i64_le(output, 16, z); store_i64_le(output, 24, magnitude_micro)
    return 32
}
