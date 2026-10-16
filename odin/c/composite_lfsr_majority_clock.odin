package composite_lfsr_majority_clock

import "core:c"

write_i64_le :: proc "contextless" (output: [^]u8, offset: c.size_t, value: i64) {
    bits := u64(value)
    for byte: u32 = 0; byte < 8; byte += 1 { output[offset + c.size_t(byte)] = u8((bits >> (8 * byte)) & 0xff) }
}

@(export)
composite_lfsr_majority_clock :: proc "c" (input: [^]i64, length: c.size_t,
        output: [^]u8, output_capacity: c.size_t) -> i64 {
    if input == nil || length != 3 do return -1
    if input[0] < 0 || input[0] > 524287 || input[1] < 0 || input[1] > 4194303 || input[2] < 0 || input[2] > 8388607 do return -1
    if output == nil || output_capacity < 32 do return -2
    s1 := u64(input[0]); s2 := u64(input[1]); s3 := u64(input[2])
    c1 := (s1 >> 8) & 1; c2 := (s2 >> 10) & 1; c3 := (s3 >> 10) & 1
    majority := c1 + c2 + c3 >= 2
    emitted := ((s1 >> 18) ~ (s2 >> 21) ~ (s3 >> 22)) & 1
    if (c1 == 1) == majority do s1 = ((s1 << 1) & 524287) | (((s1 >> 13) ~ (s1 >> 16) ~ (s1 >> 17) ~ (s1 >> 18)) & 1)
    if (c2 == 1) == majority do s2 = ((s2 << 1) & 4194303) | (((s2 >> 20) ~ (s2 >> 21)) & 1)
    if (c3 == 1) == majority do s3 = ((s3 << 1) & 8388607) | (((s3 >> 7) ~ (s3 >> 20) ~ (s3 >> 21) ~ (s3 >> 22)) & 1)
    write_i64_le(output, 0, i64(emitted)); write_i64_le(output, 8, i64(s1))
    write_i64_le(output, 16, i64(s2)); write_i64_le(output, 24, i64(s3))
    return 32
}
