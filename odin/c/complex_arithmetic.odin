package complex_arithmetic

import "core:c"

MAX_COMPONENT :: 100_000
OUTPUT_BYTES :: 16

store_i64_le :: proc "contextless" (output: [^]u8, position: int, value: i64) {
    bits := u64(value)
    for byte := 0; byte < 8; byte += 1 {
        output[position + byte] = u8((bits >> u64(byte * 8)) & 255)
    }
}

@(export)
complex_arithmetic :: proc "c" (input: [^]i64, length: c.size_t,
        output: [^]u8, output_capacity: c.size_t) -> i64 {
    if input == nil || length != 5 do return -1
    operation := input[0]
    ar := input[1]; ai := input[2]; br := input[3]; bi := input[4]
    if operation < 0 || operation > 5 do return -1
    if ar < -MAX_COMPONENT || ar > MAX_COMPONENT do return -1
    if ai < -MAX_COMPONENT || ai > MAX_COMPONENT do return -1
    if br < -MAX_COMPONENT || br > MAX_COMPONENT do return -1
    if bi < -MAX_COMPONENT || bi > MAX_COMPONENT do return -1

    real_result: i64 = 0
    imaginary_result: i64 = 0
    if operation == 0 {
        real_result = ar + br
        imaginary_result = ai + bi
    } else if operation == 1 {
        real_result = ar - br
        imaginary_result = ai - bi
    } else if operation == 2 {
        real_result = ar * br - ai * bi
        imaginary_result = ar * bi + ai * br
    } else if operation == 3 {
        denominator := br * br + bi * bi
        if denominator == 0 do return -1
        real_numerator := ar * br + ai * bi
        imaginary_numerator := ai * br - ar * bi
        if real_numerator % denominator != 0 || imaginary_numerator % denominator != 0 do return -1
        real_result = real_numerator / denominator
        imaginary_result = imaginary_numerator / denominator
    } else if operation == 4 {
        real_result = ar
        imaginary_result = -ai
    } else {
        if ar == br && ai == bi do real_result = 1
    }
    if output_capacity < OUTPUT_BYTES || output == nil do return -2
    store_i64_le(output, 0, real_result)
    store_i64_le(output, 8, imaginary_result)
    return 2
}
