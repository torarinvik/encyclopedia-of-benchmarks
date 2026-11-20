const max_modulus: i64 = 65_535;
const max_values: i64 = 12;
const max_length: usize = 15;
const radix: i64 = 4_294_967_296;

export fn barrett_reduction(input: ?[*]const i64, length: usize) i64 {
    if (input == null or length < 2 or length > max_length) return -1;
    const words = input.?;
    const modulus = words[0];
    const count_value = words[1];
    if (modulus < 2 or modulus > max_modulus or count_value < 0 or count_value > max_values) return -1;
    const count: usize = @intCast(count_value);
    if (length != 2 + count) return -1;
    const square_bound = modulus * modulus;
    for (0..count) |i| {
        const value = words[2 + i];
        if (value < 0 or value >= square_bound) return -1;
    }

    const reciprocal = @divTrunc(radix, modulus);
    var checksum: i64 = 0;
    for (0..count) |i| {
        const value = words[2 + i];
        const quotient = @divTrunc(value * reciprocal, radix);
        var remainder = value - quotient * modulus;
        if (remainder >= modulus) remainder -= modulus;
        checksum += @as(i64, @intCast(i + 1)) * (remainder + 1);
    }
    return checksum;
}
