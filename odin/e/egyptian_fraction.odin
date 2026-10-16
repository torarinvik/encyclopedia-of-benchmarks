package egyptian_fraction

// Return source-ordered unit-fraction denominators as little-endian i32s.
@(export)
egyptian_fraction :: proc "c" (input: [^]i64, length: c.size_t,
        output: [^]u8, output_capacity: c.size_t) -> i64 {
    if input == nil || length != 2 do return -1
    numerator, denominator := input[0], input[1]
    if numerator < 0 || denominator < 1 || denominator > 10 || numerator > denominator do return -1

    terms: [10]u32
    count := c.size_t(0)
    for numerator != 0 {
        unit_denominator := denominator / numerator
        if denominator % numerator != 0 do unit_denominator += 1
        terms[count] = u32(unit_denominator)
        count += 1
        numerator = numerator * unit_denominator - denominator
        denominator = denominator * unit_denominator
    }
    required := count * 4
    if output_capacity < required || (required > 0 && output == nil) do return -2
    for index := c.size_t(0); index < count; index += 1 {
        value := terms[index]
        for byte := 0; byte < 4; byte += 1 { output[index * 4 + c.size_t(byte)] = u8(value >> u32(8 * byte)) }
    }
    return i64(required)
}
