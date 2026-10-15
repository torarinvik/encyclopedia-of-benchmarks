package quadratic_roots

import "core:c"
import "core:math"

COEFFICIENT_LIMIT :: i64(1_000_000)

write_f64_le :: proc(output: [^]u8, offset: c.size_t, value: f64) {
    bits := transmute(u64)value
    for byte := 0; byte < 8; byte += 1 {
        output[offset + c.size_t(byte)] = u8(bits >> u64(8 * byte))
    }
}

@(export)
quadratic_roots :: proc "c" (values: [^]i64, length: c.size_t,
        output: [^]u8, output_capacity: c.size_t) -> i64 {
    if values == nil || length != 3 do return -1
    ai, bi, ci := values[0], values[1], values[2]
    if ai == 0 || ai < -COEFFICIENT_LIMIT || ai > COEFFICIENT_LIMIT ||
        bi < -COEFFICIENT_LIMIT || bi > COEFFICIENT_LIMIT ||
        ci < -COEFFICIENT_LIMIT || ci > COEFFICIENT_LIMIT do return -1

    a, b, c_value := f64(ai), f64(bi), f64(ci)
    discriminant := b * b - 4.0 * a * c_value
    if discriminant < 0.0 do return 0

    if discriminant == 0.0 {
        if output == nil || output_capacity < 8 do return -2
        write_f64_le(output, 0, -b / (2.0 * a))
        return 1
    }

    if output == nil || output_capacity < 16 do return -2
    square_root := math.sqrt(discriminant)
    write_f64_le(output, 0, (-b + square_root) / (2.0 * a))
    write_f64_le(output, 8, (-b - square_root) / (2.0 * a))
    return 2
}

