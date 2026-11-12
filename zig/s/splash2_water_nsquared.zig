const MAX_N: usize = 64;
const MAX_PARSEABLE: usize = 260;
const MAX_OUTPUT_WORDS: usize = 194;
const SCALE: i64 = 1_000_000;

fn truncDiv(numerator: i64, denominator: i64) i64 {
    return @divTrunc(numerator, denominator);
}

fn storeLe(output: [*]u8, offset: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |byte| output[offset + byte] = @truncate(bits >> @intCast(8 * byte));
}

export fn splash2_water_nsquared(input_opt: ?[*]const i64, length: usize,
    output_opt: ?[*]u8, capacity: usize) i64 {
    if (input_opt == null or length < 3 or length > MAX_PARSEABLE) return -1;
    const input = input_opt.?;
    const n_raw, const grid, const radius = .{ input[0], input[1], input[2] };
    if (n_raw < 0 or n_raw > @as(i64, @intCast(MAX_N)) or grid < 1 or grid > 8 or radius < 1 or radius > 4) return -1;
    const n: usize = @intCast(n_raw);
    if (length != 3 + 4 * n) return -1;
    const side = grid * radius;
    const radius2 = radius * radius;
    var x: [MAX_N]i64 = @splat(0);
    var y: [MAX_N]i64 = @splat(0);
    var z: [MAX_N]i64 = @splat(0);
    var charge: [MAX_N]i64 = @splat(0);
    for (0..n) |i| {
        const at = 3 + 4 * i;
        x[i] = input[at]; y[i] = input[at + 1]; z[i] = input[at + 2]; charge[i] = input[at + 3];
        if (x[i] < 0 or x[i] >= side or y[i] < 0 or y[i] >= side or z[i] < 0 or z[i] >= side or charge[i] < -4 or charge[i] > 4) return -1;
    }
    var force: [MAX_N][3]i64 = @splat(@splat(0));
    var energy: i64 = 0;
    var pairs: i64 = 0;
    for (0..n) |i| {
        for (i + 1..n) |j| {
            const dx = x[j] - x[i]; const dy = y[j] - y[i]; const dz = z[j] - z[i];
            const r2 = dx * dx + dy * dy + dz * dz;
            if (r2 >= radius2) continue;
            const product = charge[i] * charge[j];
            energy += truncDiv(product * (radius2 - r2) * SCALE, (1 + r2) * (1 + radius2));
            const denominator = (1 + r2) * (1 + r2);
            const fx = truncDiv(-2 * product * dx * SCALE, denominator);
            const fy = truncDiv(-2 * product * dy * SCALE, denominator);
            const fz = truncDiv(-2 * product * dz * SCALE, denominator);
            force[i][0] += fx; force[i][1] += fy; force[i][2] += fz;
            force[j][0] -= fx; force[j][1] -= fy; force[j][2] -= fz;
            pairs += 1;
        }
    }
    const words = 3 * n + 2;
    const output_bytes = 8 * words;
    if (output_opt == null or capacity < output_bytes) return -2;
    const output = output_opt.?;
    var result: [MAX_OUTPUT_WORDS]i64 = @splat(0);
    for (0..n) |i| for (0..3) |axis| result[3 * i + axis] = force[i][axis];
    result[3 * n] = energy; result[3 * n + 1] = pairs;
    for (0..words) |word| storeLe(output, 8 * word, result[word]);
    return @intCast(output_bytes);
}
