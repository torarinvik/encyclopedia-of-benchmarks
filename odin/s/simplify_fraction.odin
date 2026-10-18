package simplify_fraction

import "core:c"

MAX_ABS_COMPONENT :: i64(1_000_000)
OUTPUT_BYTES :: 16

magnitude :: proc(value: i64) -> u64 { if value < 0 do return u64(-value); return u64(value) }
gcd_positive :: proc(a, b: u64) -> u64 {
    x, y := a, b
    for y != 0 { r := x%y; x=y; y=r }
    return x
}
put_i64_le :: proc(output: [^]u8, offset: int, value: i64) {
    bits := transmute(u64)value
    for byte := 0; byte < 8; byte += 1 { output[offset+byte] = u8(bits >> (8*byte)) }
}

@(export)
simplify_fraction :: proc "c" (input: [^]i64, input_length: c.size_t,
    output: [^]u8, capacity: c.size_t) -> i64 {
    if input == nil || input_length != 2 do return -1
    numerator, denominator := input[0], input[1]
    if numerator < -MAX_ABS_COMPONENT || numerator > MAX_ABS_COMPONENT ||
        denominator < -MAX_ABS_COMPONENT || denominator > MAX_ABS_COMPONENT || denominator == 0 do return -1
    divisor := i64(gcd_positive(magnitude(numerator), magnitude(denominator)))
    reduced_numerator, reduced_denominator := numerator/divisor, denominator/divisor
    staged: [OUTPUT_BYTES]u8
    put_i64_le(&staged[0], 0, reduced_numerator)
    put_i64_le(&staged[0], 8, reduced_denominator)
    if output == nil || capacity < c.size_t(OUTPUT_BYTES) do return -2
    for i := 0; i < OUTPUT_BYTES; i += 1 { output[i] = staged[i] }
    return OUTPUT_BYTES
}
