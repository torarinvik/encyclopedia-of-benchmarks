const max_terms: usize = 16;
const max_length: usize = 34;
const max_mantissa: i64 = 16_777_216;
const output_scale: f64 = 1_073_741_824.0;

const SumPair = struct { high: f64, low: f64 };

fn twoSum(a: f64, b: f64) SumPair {
    const rounded = a+b;
    const b_virtual = rounded-a;
    const a_virtual = rounded-b_virtual;
    const b_roundoff = b-b_virtual;
    const a_roundoff = a-a_virtual;
    return .{ .high = rounded, .low = a_roundoff+b_roundoff };
}

fn growExpansion(expansion: []const f64, value: f64, grown: []f64) usize {
    var q = value;
    var grown_count: usize = 0;
    for (expansion) |component| {
        const pair = twoSum(q,component);
        if (pair.low != 0.0) {
            grown[grown_count] = pair.low;
            grown_count += 1;
        }
        q = pair.high;
    }
    if (q != 0.0 or grown_count == 0) {
        grown[grown_count] = q;
        grown_count += 1;
    }
    return grown_count;
}

export fn shewchuk_expansion_sum(input: ?[*]const i64, length: usize) i64 {
    if (input == null or length < 1 or length > max_length) return -1;
    const words = input.?;
    if (words[0] < 0 or words[0] > @as(i64,@intCast(max_terms))) return -1;
    const n: usize = @intCast(words[0]);
    if (length != 1+2*n) return -1;

    var expansion = [_]f64{0.0} ** (max_terms+1);
    var grown = [_]f64{0.0} ** (max_terms+1);
    var expansion_count: usize = 0;
    for (0..n) |i| {
        const mantissa = words[1+2*i];
        const exponent = words[2+2*i];
        if (mantissa < -max_mantissa or mantissa > max_mantissa or exponent < -30 or exponent > 0) return -1;
        var value: f64 = @floatFromInt(mantissa);
        var shift: i64 = 0;
        while (shift > exponent) : (shift -= 1) value *= 0.5;
        if (value != 0.0) {
            const grown_count = growExpansion(expansion[0..expansion_count],value,grown[0..]);
            @memcpy(expansion[0..grown_count],grown[0..grown_count]);
            expansion_count = grown_count;
        }
    }
    var result: i64 = (@as(i64,1) << 58)+1;
    for (expansion[0..expansion_count]) |component| {
        result += @as(i64,@intFromFloat(component*output_scale));
    }
    return result;
}
