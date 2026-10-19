const INPUT_COUNT: usize = 4;
const MAX_ROOTS: usize = 3;

fn solveCubic(input: *const [INPUT_COUNT]f64, roots: *[MAX_ROOTS]f64) i64 {
    const a = input[0];
    const b = input[1];
    const c = input[2];
    const d = input[3];
    const a1 = b / a;
    const a2 = c / a;
    const a3 = d / a;
    const q = (a1 * a1 - 3.0 * a2) / 9.0;
    const r = (2.0 * a1 * a1 * a1 - 9.0 * a1 * a2 + 27.0 * a3) / 54.0;
    const discriminant = r * r - q * q * q;
    if (discriminant == 0.0) return -1;
    if (discriminant <= 0.0) {
        const pi = @acos(-1.0);
        const theta = @acos(r / @sqrt(q * q * q));
        roots[0] = -2.0 * @sqrt(q) * @cos(theta / 3.0) - a1 / 3.0;
        roots[1] = -2.0 * @sqrt(q) * @cos((theta + 2.0 * pi) / 3.0) - a1 / 3.0;
        roots[2] = -2.0 * @sqrt(q) * @cos((theta + 4.0 * pi) / 3.0) - a1 / 3.0;
        return 3;
    }
    var root = std.math.pow(f64, @sqrt(discriminant) + @abs(r), 1.0 / 3.0);
    root += q / root;
    root *= if (r < 0.0) 1.0 else -1.0;
    roots[0] = root - a1 / 3.0;
    return 1;
}

pub export fn mibench_automotive_basicmath_cubic(
    input_opt: ?[*]const f64,
    input_length: usize,
    output_opt: ?[*]f64,
    output_capacity: usize,
) i64 {
    const input = input_opt orelse return -1;
    if (input_length != INPUT_COUNT) return -1;
    for (0..INPUT_COUNT) |index| {
        if (!std.math.isFinite(input[index]) or input[index] < -100.0 or input[index] > 100.0) return -1;
    }
    if (input[0] > -1.0 and input[0] < 1.0) return -1;
    var roots: [MAX_ROOTS]f64 = undefined;
    const coefficients: *const [INPUT_COUNT]f64 = @ptrCast(input);
    const count = solveCubic(coefficients, &roots);
    if (count < 0) return -1;
    const output = output_opt orelse return -2;
    if (output_capacity < @as(usize, @intCast(count))) return -2;
    for (0..@as(usize, @intCast(count))) |index| output[index] = roots[index];
    return count;
}
