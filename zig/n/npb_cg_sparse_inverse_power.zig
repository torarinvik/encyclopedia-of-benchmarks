const std = @import("std");

const max_n: usize = 32;
const max_outer: usize = 8;
const max_steps: usize = 25;
const max_micro: i64 = 1_000_000_000;
const scale: f64 = 1_000_000.0;

const Parsed = struct { n: usize, outer: usize, steps: usize, nnz: usize };

fn valid(v: []const i64) ?Parsed {
    if (v.len < 8 or v.len > max_n + 6 + 2 * (max_n * 6)) return null;
    if (v[0] < 1 or v[0] > @as(i64, @intCast(max_n)) or
        v[1] < 1 or v[1] > @as(i64, @intCast(max_outer)) or
        v[2] < 1 or v[2] > @as(i64, @intCast(max_steps)) or v[2] > v[0] or
        v[3] < -max_micro or v[3] > max_micro or v[4] < v[0] or v[4] > 6 * v[0]) return null;
    const n: usize = @intCast(v[0]);
    const outer: usize = @intCast(v[1]);
    const steps: usize = @intCast(v[2]);
    const nnz: usize = @intCast(v[4]);
    if (v.len != n + 6 + 2 * nnz) return null;
    const rp: usize = 5;
    const columns = rp + n + 1;
    const entries = columns + nnz;
    if (v[rp] != 0 or v[rp + n] != @as(i64, @intCast(nnz))) return null;
    for (0..n) |row| {
        const begin = v[rp + row];
        const end = v[rp + row + 1];
        if (begin < 0 or begin >= end or end > @as(i64, @intCast(nnz))) return null;
        var diagonal: i64 = 0;
        var off_sum: i64 = 0;
        var previous: i64 = -1;
        for (@intCast(begin)..@intCast(end)) |edge| {
            const column = v[columns + edge];
            const value = v[entries + edge];
            if (column < 0 or column >= @as(i64, @intCast(n)) or column <= previous or
                value == 0 or value < -max_micro or value > max_micro) return null;
            previous = column;
            if (column == @as(i64, @intCast(row))) diagonal = value else off_sum += @intCast(@abs(value));
        }
        if (diagonal <= 0 or diagonal <= off_sum) return null;
    }
    for (0..n) |row| {
        for (@intCast(v[rp + row])..@intCast(v[rp + row + 1])) |edge| {
            const column: usize = @intCast(v[columns + edge]);
            var found = false;
            for (@intCast(v[rp + column])..@intCast(v[rp + column + 1])) |reverse| {
                if (v[columns + reverse] == @as(i64, @intCast(row)) and v[entries + reverse] == v[entries + edge]) {
                    found = true;
                    break;
                }
            }
            if (!found) return null;
        }
    }
    return .{ .n = n, .outer = outer, .steps = steps, .nnz = nnz };
}

fn matvec(n: usize, nnz: usize, v: []const i64, vector: *const [max_n]f64, product: *[max_n]f64) void {
    const rp: usize = 5;
    const columns = rp + n + 1;
    const entries = columns + nnz;
    for (0..n) |row| {
        var total: f64 = 0.0;
        for (@intCast(v[rp + row])..@intCast(v[rp + row + 1])) |edge|
            total += (@as(f64, @floatFromInt(v[entries + edge])) / scale) * vector.*[@intCast(v[columns + edge])];
        product.*[row] = total;
    }
}

fn writeF64Le(output: [*]u8, offset: usize, value: f64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |byte| output[offset + byte] = @truncate(bits >> @intCast(8 * byte));
}

export fn npb_cg_sparse_inverse_power(input: ?[*]const i64, length: usize,
    output_opt: ?[*]u8, capacity: usize) i64 {
    if (input == null) return -1;
    if (length < 8 or length > max_n + 6 + 2 * (max_n * 6)) return -1;
    const v = input.?[0..length];
    const parsed = valid(v) orelse return -1;
    const output_bytes = parsed.outer * 16;
    if (output_opt == null or capacity < output_bytes) return -2;
    const output = output_opt.?;
    var x: [max_n]f64 = @splat(0.0);
    var z: [max_n]f64 = @splat(0.0);
    var residual: [max_n]f64 = @splat(0.0);
    var direction: [max_n]f64 = @splat(0.0);
    var product: [max_n]f64 = @splat(0.0);
    var az: [max_n]f64 = @splat(0.0);
    for (0..parsed.n) |i| x[i] = 1.0;
    for (0..parsed.outer) |outer| {
        var rhs2: f64 = 0.0;
        for (0..parsed.n) |i| {
            z[i] = 0.0;
            residual[i] = x[i];
            direction[i] = x[i];
            rhs2 += residual[i] * residual[i];
        }
        var rr = rhs2;
        for (0..parsed.steps) |_| {
            if (rr <= 0.0) break;
            matvec(parsed.n, parsed.nnz, v, &direction, &product);
            var denominator: f64 = 0.0;
            for (0..parsed.n) |i| denominator += direction[i] * product[i];
            if (!(denominator > 0.0) or !std.math.isFinite(denominator)) return -1;
            const alpha = rr / denominator;
            for (0..parsed.n) |i| {
                z[i] += alpha * direction[i];
                residual[i] -= alpha * product[i];
            }
            var next: f64 = 0.0;
            for (0..parsed.n) |i| next += residual[i] * residual[i];
            if (next <= rhs2 * 1.0e-28) { rr = next; break; }
            const beta = next / rr;
            for (0..parsed.n) |i| direction[i] = residual[i] + beta * direction[i];
            rr = next;
        }
        matvec(parsed.n, parsed.nnz, v, &z, &az);
        var explicit2: f64 = 0.0;
        var dot: f64 = 0.0;
        var z2: f64 = 0.0;
        for (0..parsed.n) |i| {
            const difference = x[i] - az[i];
            explicit2 += difference * difference;
            dot += x[i] * z[i];
            z2 += z[i] * z[i];
        }
        if (!(dot > 0.0) or !(z2 > 0.0) or !std.math.isFinite(dot) or !std.math.isFinite(z2)) return -1;
        const estimate = @as(f64, @floatFromInt(v[3])) / scale + 1.0 / dot;
        const residual_norm = @sqrt(explicit2);
        if (!std.math.isFinite(estimate) or !std.math.isFinite(residual_norm)) return -1;
        writeF64Le(output, outer * 16, estimate);
        writeF64Le(output, outer * 16 + 8, residual_norm);
        const z_norm = @sqrt(z2);
        for (0..parsed.n) |i| x[i] = z[i] / z_norm;
    }
    return @intCast(output_bytes);
}
