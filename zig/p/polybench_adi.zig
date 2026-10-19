const max_dimension: usize = 32;
const max_cells: usize = max_dimension * max_dimension;
const max_tsteps: i64 = 20;

fn write_f64_le(output: [*]u8, offset: usize, value: f64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |byte| output[offset + byte] = @truncate(bits >> @intCast(8 * byte));
}

export fn polybench_adi(values: [*c]const i64, length: usize,
                        output: [*c]u8, output_capacity: usize) i64 {
    if (values == null or length != 2 or values[0] < 1 or values[0] > @as(i64, @intCast(max_dimension)) or
        values[1] < 1 or values[1] > max_tsteps) return -1;
    const n: usize = @intCast(values[0]);
    const tsteps: usize = @intCast(values[1]);
    const cells = n * n;
    const output_bytes = cells * 8;
    if (output == null or output_capacity < output_bytes) return -2;

    var u: [max_cells]f64 = @splat(0.0);
    var v: [max_cells]f64 = @splat(0.0);
    var p: [max_cells]f64 = @splat(0.0);
    var q: [max_cells]f64 = @splat(0.0);
    for (0..n) |i| {
        for (0..n) |j| {
            u[i * n + j] = @as(f64, @floatFromInt(i + n - j)) / @as(f64, @floatFromInt(n));
        }
    }

    const dx = 1.0 / @as(f64, @floatFromInt(n));
    const dy = 1.0 / @as(f64, @floatFromInt(n));
    const dt = 1.0 / @as(f64, @floatFromInt(tsteps));
    const b1 = 2.0;
    const b2 = 1.0;
    const mul1 = b1 * dt / (dx * dx);
    const mul2 = b2 * dt / (dy * dy);
    const a = -mul1 / 2.0;
    const b = 1.0 + mul1;
    const c = a;
    const d = -mul2 / 2.0;
    const e = 1.0 + mul2;
    const f = d;

    for (0..tsteps) |_| {
        for (1..n - 1) |i| {
            v[i] = 1.0;
            p[i * n] = 0.0;
            q[i * n] = v[i];
            for (1..n - 1) |j| {
                p[i * n + j] = -c / (a * p[i * n + j - 1] + b);
                q[i * n + j] = (-d * u[j * n + i - 1] + (1.0 + 2.0 * d) * u[j * n + i]
                                - f * u[j * n + i + 1] - a * q[i * n + j - 1])
                               / (a * p[i * n + j - 1] + b);
            }
            v[(n - 1) * n + i] = 1.0;
            var j = n - 1;
            while (j > 1) {
                j -= 1;
                v[j * n + i] = p[i * n + j] * v[(j + 1) * n + i] + q[i * n + j];
            }
        }

        for (1..n - 1) |i| {
            u[i * n] = 1.0;
            p[i * n] = 0.0;
            q[i * n] = u[i * n];
            for (1..n - 1) |j| {
                p[i * n + j] = -f / (d * p[i * n + j - 1] + e);
                q[i * n + j] = (-a * v[(i - 1) * n + j] + (1.0 + 2.0 * a) * v[i * n + j]
                                - c * v[(i + 1) * n + j] - d * q[i * n + j - 1])
                               / (d * p[i * n + j - 1] + e);
            }
            u[i * n + n - 1] = 1.0;
            var j = n - 1;
            while (j > 1) {
                j -= 1;
                u[i * n + j] = p[i * n + j] * u[i * n + j + 1] + q[i * n + j];
            }
        }
    }

    for (0..cells) |index| write_f64_le(output, index * 8, u[index]);
    return @intCast(output_bytes);
}
