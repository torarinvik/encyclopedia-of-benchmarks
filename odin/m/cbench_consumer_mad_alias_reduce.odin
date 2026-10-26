package cbench_consumer_mad_alias_reduce

import "core:c"

CS :: [8]i64{0x0db84a81, 0x0e1b9d7f, 0x0f31adcf, 0x0fbba815, 0x0feda417, 0x0ffc8fc8, 0x0fff964c, 0x0ffff8d3}
CA :: [8]i64{-0x083b5fe7, -0x078c36d2, -0x05039814, -0x02e91dd1, -0x0183603a, -0x00a7cb87, -0x003a2847, -0x000f27b4}

floor_div :: proc "contextless" (value, divisor: i64) -> i64 {
    quotient := value / divisor
    if value % divisor < 0 do return quotient - 1
    return quotient
}

mad_mul :: proc "contextless" (left, right: i64) -> i64 {
    return floor_div(left + 2048, 4096) * floor_div(right + 32768, 65536)
}

put_i32_le :: proc "contextless" (output: [^]u8, offset: int, value: i64) {
    bits := u32(i32(value))
    for byte in 0..4 { output[offset + byte] = u8((bits >> u32(byte * 8)) & 255) }
}

@(export)
cbench_consumer_mad_alias_reduce :: proc "c" (input: [^]i64, length: c.size_t,
        output: [^]u8, capacity: c.size_t) -> i64 {
    if input == nil || length < 1 || length > 65 do return -1
    if input[0] < 1 || input[0] > 4 do return -1
    boundaries := int(input[0])
    if length != c.size_t(1 + 16 * boundaries) do return -1
    for i := 1; i < int(length); i += 1 {
        if input[i] < -100_000_000 || input[i] > 100_000_000 do return -1
    }
    output_size := 64 * boundaries
    staged: [64]i64
    for boundary := 0; boundary < boundaries; boundary += 1 {
        base := 1 + 16 * boundary
        for i := 0; i < 8; i += 1 {
            a, b := input[base + 2 * i], input[base + 2 * i + 1]
            staged[16 * boundary + 2 * i] = mad_mul(a, CS[i]) + mad_mul(-b, CA[i])
            staged[16 * boundary + 2 * i + 1] = mad_mul(b, CS[i]) + mad_mul(a, CA[i])
        }
    }
    if output == nil || capacity < c.size_t(output_size) do return -2
    for i := 0; i < 16 * boundaries; i += 1 { put_i32_le(output, 4 * i, staged[i]) }
    return i64(output_size)
}
