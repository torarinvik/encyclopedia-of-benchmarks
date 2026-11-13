const FACTOR_LOG_32 = [_]u32{
    0x00000000, 0x00000000, 0xd3cfd984, 0x9ee62e18,
    0xe83d9070, 0xb59e81e0, 0xa17407c0, 0xce601f80,
    0xf4807f00, 0xe701fe00, 0xbe07fc00, 0xfc1ff800,
    0xf87ff000, 0xf1ffe000, 0xe7ffc000, 0xdfff8000,
    0xffff0000, 0xfffe0000, 0xfffc0000, 0xfff80000,
    0xfff00000, 0xffe00000, 0xffc00000, 0xff800000,
    0xff000000, 0xfe000000, 0xfc000000, 0xf8000000,
    0xf0000000, 0xe0000000, 0xc0000000, 0x80000000,
};

fn factoringMask(d: u32) u64 {
    return if (d == 32) 0xffffffff else (@as(u64, 1) << @intCast(d)) - 1;
}

fn factoringLog(remainder_input: u64, value_input: u64, d: u32, modulus: u64, mask: u64) u64 {
    var remainder = remainder_input;
    var value = value_input;
    var bit: u32 = 2;
    while (bit < d) : (bit += 1) {
        if ((value & (@as(u64, 1) << @intCast(bit))) != 0) {
            value = (value + (value << @intCast(bit))) & mask;
            remainder = (remainder + modulus - (@as(u64, FACTOR_LOG_32[@intCast(bit)]) & mask)) & mask;
        }
    }
    return remainder;
}

fn factoringExp(remainder_input: u64, exponent_input: u64, d: u32, modulus: u64, mask: u64) u64 {
    var remainder = remainder_input;
    var exponent = exponent_input;
    var bit: u32 = 2;
    while (bit < d) : (bit += 1) {
        if ((exponent & (@as(u64, 1) << @intCast(bit))) != 0) {
            remainder = (remainder + (remainder << @intCast(bit))) & mask;
            exponent = (exponent + modulus - (@as(u64, FACTOR_LOG_32[@intCast(bit)]) & mask)) & mask;
        }
    }
    return remainder;
}

export fn factoring_exponentiation(input: ?[*]const i64, length: usize) i64 {
    if (input == null or length != 4) return -1;
    const values = input.?;
    const remainder_input = values[0];
    const base_input = values[1];
    const exponent_input = values[2];
    const d_input = values[3];
    if (d_input < 3 or d_input > 32 or remainder_input < 0 or base_input < 1 or
        exponent_input < 0 or exponent_input > 4294967295) return -1;
    const d: u32 = @intCast(d_input);
    const mask = factoringMask(d);
    const modulus = mask + 1;
    if (@as(u64, @intCast(remainder_input)) >= modulus or
        @as(u64, @intCast(base_input)) >= modulus or
        (@as(u64, @intCast(base_input)) & 1) == 0) return -1;
    var remainder: u64 = @intCast(remainder_input);
    var base: u64 = @intCast(base_input);
    const exponent: u64 = @intCast(exponent_input);
    if ((base & 2) != 0) {
        base = (modulus - base) & mask;
        if ((exponent & 1) != 0) remainder = (modulus - remainder) & mask;
    }
    const log_value = factoringLog(0, base, d, modulus, mask);
    const scaled_log = (log_value * exponent) & mask;
    return @intCast(factoringExp(remainder, scaled_log, d, modulus, mask));
}
