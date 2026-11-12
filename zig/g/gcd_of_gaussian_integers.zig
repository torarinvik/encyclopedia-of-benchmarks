const max_t: usize = 8;
const max_component: i64 = 1_000_000;
const max_output_bytes: usize = 64;
const Gaussian = struct { real: i64, imaginary: i64 };

fn nearestQuotient(numerator: i64, denominator: i64) i64 {
    const sign: i64 = if (numerator < 0) -1 else 1;
    const magnitude = if (numerator < 0) -numerator else numerator;
    var quotient = @divTrunc(magnitude, denominator);
    const remainder = @rem(magnitude, denominator);
    if (2 * remainder >= denominator) quotient += 1;
    return sign * quotient;
}

fn writeU32(output: [*]u8, offset: usize, value: u32) void {
    output[offset] = @truncate(value);
    output[offset + 1] = @truncate(value >> 8);
    output[offset + 2] = @truncate(value >> 16);
    output[offset + 3] = @truncate(value >> 24);
}

fn gaussianGcd(ar_input: i64, ai_input: i64, br_input: i64, bi_input: i64) Gaussian {
    var ar = ar_input;
    var ai = ai_input;
    var br = br_input;
    var bi = bi_input;
    while (br != 0 or bi != 0) {
        const denominator = br * br + bi * bi;
        const qr = nearestQuotient(ar * br + ai * bi, denominator);
        const qi = nearestQuotient(ai * br - ar * bi, denominator);
        const rr = ar - (qr * br - qi * bi);
        const ri = ai - (qr * bi + qi * br);
        ar = br;
        ai = bi;
        br = rr;
        bi = ri;
    }
    if (ar != 0 or ai != 0) {
        for (0..4) |_| {
            if (ar > 0 and ai >= 0) break;
            const old_real = ar;
            ar = -ai;
            ai = old_real;
        }
    }
    return .{ .real = ar, .imaginary = ai };
}

export fn gcd_of_gaussian_integers(input_opt: ?[*]const i64, length: usize,
    output_opt: ?[*]u8, capacity: usize) i64 {
    if (input_opt == null or length < 5 or length > 1 + 4 * max_t) return -1;
    const input = input_opt.?;
    const t64 = input[0];
    if (t64 < 1 or t64 > @as(i64, @intCast(max_t))) return -1;
    const t: usize = @intCast(t64);
    if (length != 1 + 4 * t) return -1;

    var values: [max_t * 4]i64 = @splat(0);
    for (0..4 * t) |index| {
        const value = input[index + 1];
        if (value < -max_component or value > max_component) return -1;
        values[index] = value;
    }
    const required = 8 * t;
    if (output_opt == null or capacity < required or required > max_output_bytes) return -2;
    const output = output_opt.?;

    for (0..t) |test| {
        const result = gaussianGcd(values[4 * test], values[4 * test + 1],
            values[4 * test + 2], values[4 * test + 3]);
        writeU32(output, 8 * test, @intCast(result.real));
        writeU32(output, 8 * test + 4, @intCast(result.imaginary));
    }
    return @intCast(required);
}
