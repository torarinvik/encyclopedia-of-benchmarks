/// Return source-ordered unit-fraction denominators as little-endian i32s.
export fn egyptian_fraction(input: [*c]const i64, length: usize,
                            output: [*c]u8, output_capacity: usize) i64 {
    if (input == null or length != 2) return -1;
    var numerator = input[0];
    var denominator = input[1];
    if (numerator < 0 or denominator < 1 or denominator > 10 or numerator > denominator) return -1;

    var terms: [10]u32 = @splat(0);
    var count: usize = 0;
    while (numerator != 0) {
        var unit_denominator = @divTrunc(denominator, numerator);
        if (@rem(denominator, numerator) != 0) unit_denominator += 1;
        terms[count] = @intCast(unit_denominator);
        count += 1;
        numerator = numerator * unit_denominator - denominator;
        denominator = denominator * unit_denominator;
    }
    const required = count * 4;
    if (output_capacity < required or (required > 0 and output == null)) return -2;
    for (0..count) |index| {
        const value = terms[index];
        for (0..4) |byte| output[index * 4 + byte] = @truncate(value >> @intCast(8 * byte));
    }
    return @intCast(required);
}
