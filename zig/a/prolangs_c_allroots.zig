const REQUIRED_BYTES: usize = 24;
const NEWTON_EPSILON: f64 = 5.0e-6;
const MAX_NEWTON_ITERATIONS: usize = 40;

fn absoluteValue(value: f64) f64 { return if (value < 0.0) -value else value; }

fn hornerValueAndDerivative(coefficients: []const f64, x: f64) struct { value: f64, derivative: f64 } {
    const degree = coefficients.len - 1;
    var value = coefficients[degree];
    var slope = value;
    var j = degree;
    while (j > 1) {
        j -= 1;
        value = x * value + coefficients[j];
        slope = x * slope + value;
    }
    value = x * value + coefficients[0];
    return .{ .value = value, .derivative = slope };
}

fn newtonRoot(coefficients: []const f64, lower_bound: f64, upper_bound: f64) f64 {
    var lower = lower_bound;
    var upper = upper_bound;
    if (upper < lower) { const temporary = lower; lower = upper; upper = temporary; }
    var previous = lower;
    var current = (lower + upper) / 2.0;
    var iterations: usize = 0;
    while (absoluteValue(current - previous) / absoluteValue(current) > NEWTON_EPSILON and
           iterations <= MAX_NEWTON_ITERATIONS) {
        previous = current;
        const evaluation = hornerValueAndDerivative(coefficients, current);
        current -= evaluation.value / evaluation.derivative;
        iterations += 1;
    }
    return current;
}

fn storeF64Le(output: [*]u8, offset: usize, value: f64) void {
    const bits = @as(u64, @bitCast(value));
    for (0..8) |i| output[offset + i] = @truncate(bits >> @intCast(8 * i));
}

fn solve(staged: [*]u8) void {
    const original = [_]f64{ 4.0, -4.0, -1.0, 1.0 };
    const coefficients = original;
    var upper: f64 = 0.0;
    for (coefficients) |coefficient| upper += absoluteValue(coefficient);
    upper /= absoluteValue(coefficients[3]);
    const lower = -upper - 1.0;

    const first_root = newtonRoot(&coefficients, lower, upper);
    var deflated = [_]f64{ 0.0, 0.0, 0.0 };
    deflated[2] = coefficients[3];
    var i: usize = 2;
    while (i > 0) {
        i -= 1;
        deflated[i] = deflated[i + 1] * first_root + coefficients[i + 1];
    }

    const discriminant = deflated[1] * deflated[1] - 4.0 * deflated[2] * deflated[0];
    const plus_root = (-deflated[1] + @sqrt(discriminant)) / (2.0 * deflated[2]);
    const minus_root = (-deflated[1] - @sqrt(discriminant)) / (2.0 * deflated[2]);
    const refined_plus = newtonRoot(&original, plus_root - 0.5, plus_root + 0.5);
    const refined_minus = newtonRoot(&original, minus_root - 0.5, minus_root + 0.5);
    storeF64Le(staged, 0, first_root);
    storeF64Le(staged, 8, refined_plus);
    storeF64Le(staged, 16, refined_minus);
}

pub export fn prolangs_c_allroots(values: [*c]const i64, length: usize,
    output: [*c]u8, output_capacity: usize) i64 {
    if (values == null or length != 4) return -1;
    if (values[0] != 4 or values[1] != -4 or values[2] != -1 or values[3] != 1) return -1;
    if (output == null or output_capacity < REQUIRED_BYTES) return -2;
    var staged: [REQUIRED_BYTES]u8 = @splat(0);
    solve(&staged[0]);
    for (0..REQUIRED_BYTES) |index| output[index] = staged[index];
    return @intCast(REQUIRED_BYTES);
}
