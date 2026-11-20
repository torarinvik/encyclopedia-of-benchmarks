const MAX_DEGREE: usize = 8;
const MAX_ITERATIONS: usize = 4;
const MAX_INPUT_LENGTH: usize = 14;
const MODULUS: i64 = 998244353;

fn normalize(value: i64) i64 {
    const reduced = @mod(value, MODULUS);
    return if (reduced < 0) reduced + MODULUS else reduced;
}

fn power(base_input: i64, exponent_input: i64) i64 {
    var base = normalize(base_input);
    var exponent = exponent_input;
    var result: i64 = 1;
    while (exponent > 0) {
        if ((exponent & 1) != 0) result = @mod(result * base, MODULUS);
        base = @mod(base * base, MODULUS);
        exponent >>= 1;
    }
    return result;
}

fn storeI64Le(output: [*]u8, offset: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |byte| output[offset + byte] = @truncate(bits >> @intCast(8 * byte));
}

export fn bairstow_quadratic_factor_iteration(input_opt: ?[*]const i64,
    length: usize, output_opt: ?[*]u8, capacity: usize) i64 {
    if (input_opt == null or length < 1 or length > MAX_INPUT_LENGTH) return -1;
    const input = input_opt.?;
    const degree_value = input[0];
    if (degree_value < 3 or degree_value > @as(i64, @intCast(MAX_DEGREE))) return -1;
    const degree: usize = @intCast(degree_value);
    if (length != degree + 5) return -1;

    var coefficients: [MAX_DEGREE + 1]i64 = @splat(0);
    for (0..degree + 1) |i| {
        coefficients[i] = input[1 + i];
        if (coefficients[i] < 0 or coefficients[i] >= MODULUS) return -1;
    }
    var s_value = input[degree + 2];
    var t_value = input[degree + 3];
    const iterations_value = input[degree + 4];
    if (coefficients[degree] == 0 or s_value < 0 or s_value >= MODULUS
            or t_value < 0 or t_value >= MODULUS
            or iterations_value < 1 or iterations_value > @as(i64, @intCast(MAX_ITERATIONS))) return -1;
    const iterations: usize = @intCast(iterations_value);
    var s_trace: [MAX_ITERATIONS + 1]i64 = @splat(0);
    var t_trace: [MAX_ITERATIONS + 1]i64 = @splat(0);
    s_trace[0] = s_value;
    t_trace[0] = t_value;
    for (0..iterations) |step| {
        var q: [MAX_DEGREE + 2]i64 = @splat(0);
        var r: [MAX_DEGREE + 2]i64 = @splat(0);
        q[degree] = coefficients[degree];
        r[degree] = coefficients[degree];
        var cursor = degree;
        while (cursor > 0) {
            cursor -= 1;
            q[cursor] = normalize(coefficients[cursor] + s_value * q[cursor + 1]
                                  + t_value * q[cursor + 2]);
            r[cursor] = normalize(q[cursor] + s_value * r[cursor + 1]
                                  + t_value * r[cursor + 2]);
        }
        const r2 = r[2];
        const r3 = r[3];
        const q0 = q[0];
        const q1 = q[1];
        const ell = normalize(s_value * r2 + t_value * r3);
        const denominator = normalize(r2 * r2 - ell * r3);
        if (denominator == 0) return -1;
        const inverse = power(denominator, MODULUS - 2);
        const delta_s = @mod(normalize(r3 * q0 - r2 * q1) * inverse, MODULUS);
        const delta_t = @mod(normalize(ell * q1 - r2 * q0) * inverse, MODULUS);
        s_value = normalize(s_value + delta_s);
        t_value = normalize(t_value + delta_t);
        s_trace[step + 1] = s_value;
        t_trace[step + 1] = t_value;
    }

    const output_bytes = 8 * (2 * iterations + 3);
    if (output_opt == null or capacity < output_bytes) return -2;
    const output = output_opt.?;
    storeI64Le(output, 0, @intCast(iterations + 1));
    for (0..iterations + 1) |i| {
        storeI64Le(output, 8 * (1 + 2 * i), s_trace[i]);
        storeI64Le(output, 8 * (2 + 2 * i), t_trace[i]);
    }
    return @intCast(output_bytes);
}
