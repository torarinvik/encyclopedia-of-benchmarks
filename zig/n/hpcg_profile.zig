const std = @import("std");

const max_n: usize = 32;
const max_coarse: usize = 16;
const max_steps: usize = 12;
const max_micro: i64 = 1_000_000_000;
const scale: f64 = 1_000_000.0;
const Parsed = struct { n: usize, steps: usize, nnz: usize };

fn valid(v: []const i64, diagonal: *[max_n]f64) ?Parsed {
    if (v.len < 8 or v.len > 452 or v[0] < 1 or v[0] > @as(i64, @intCast(max_n)) or
        v[1] < 1 or v[1] > @as(i64, @intCast(max_steps)) or v[1] > v[0] or
        v[2] < v[0] or v[2] > 6 * v[0]) return null;
    const n: usize = @intCast(v[0]);
    const steps: usize = @intCast(v[1]);
    const nnz: usize = @intCast(v[2]);
    if (v.len != 4 + 2 * n + 2 * nnz or v[3] != 0 or v[3 + n] != @as(i64, @intCast(nnz))) return null;
    const col = 4 + n;
    const val = col + nnz;
    const rhs = val + nnz;
    for (0..n) |row| {
        const begin = v[3 + row];
        const end = v[4 + row];
        if (begin < 0 or begin >= end or end > @as(i64, @intCast(nnz)) or end - begin > 6) return null;
        var d: i64 = 0;
        var off: i64 = 0;
        var previous: i64 = -1;
        for (@intCast(begin)..@intCast(end)) |edge| {
            const c = v[col + edge];
            const a = v[val + edge];
            if (c < 0 or c >= @as(i64, @intCast(n)) or c <= previous or a == 0 or a < -max_micro or a > max_micro) return null;
            previous = c;
            if (c == @as(i64, @intCast(row))) d = a else off += @intCast(@abs(a));
        }
        if (d <= 0 or d <= off or v[rhs + row] < -max_micro or v[rhs + row] > max_micro) return null;
        diagonal[row] = @as(f64, @floatFromInt(d)) / scale;
    }
    for (0..n) |row| {
        for (@intCast(v[3 + row])..@intCast(v[4 + row])) |edge| {
            const c: usize = @intCast(v[col + edge]);
            var found = false;
            for (@intCast(v[3 + c])..@intCast(v[4 + c])) |rev| {
                if (v[col + rev] == @as(i64, @intCast(row)) and v[val + rev] == v[val + edge]) { found = true; break; }
            }
            if (!found) return null;
        }
    }
    return .{ .n = n, .steps = steps, .nnz = nnz };
}

fn matvec(n: usize, nnz: usize, v: []const i64, x: *const [max_n]f64, y: *[max_n]f64) void {
    const col = 4 + n;
    const val = col + nnz;
    for (0..n) |row| {
        var sum: f64 = 0.0;
        for (@intCast(v[3 + row])..@intCast(v[4 + row])) |edge| sum += @as(f64, @floatFromInt(v[val + edge])) / scale * x[@intCast(v[col + edge])];
        y[row] = sum;
    }
}

fn coarseSolve(n: usize, nnz: usize, v: []const i64, rhs: *const [max_coarse]f64, result: *[max_coarse]f64) bool {
    const cn = (n + 1) / 2;
    const col = 4 + n;
    const val = col + nnz;
    var a: [max_coarse][max_coarse]f64 = undefined;
    var l: [max_coarse][max_coarse]f64 = undefined;
    for (0..max_coarse) |i| {
        for (0..max_coarse) |j| { a[i][j] = 0; l[i][j] = 0; }
    }
    for (0..n) |row| {
        for (@intCast(v[3 + row])..@intCast(v[4 + row])) |edge| {
            a[row / 2][@intCast(v[col + edge]) / 2] += @as(f64, @floatFromInt(v[val + edge])) / scale;
        }
    }
    for (0..cn) |i| {
        for (0..i + 1) |j| {
            var value = a[i][j];
            for (0..j) |k| value -= l[i][k] * l[j][k];
            if (i == j) { if (!(value > 0.0)) return false; l[i][j] = @sqrt(value); }
            else l[i][j] = value / l[j][j];
        }
    }
    var y: [max_coarse]f64 = @splat(0.0);
    for (0..cn) |i| {
        var value = rhs[i];
        for (0..i) |j| value -= l[i][j] * y[j];
        y[i] = value / l[i][i];
    }
    var ii = cn;
    while (ii > 0) {
        ii -= 1;
        var value = y[ii];
        for (ii + 1..cn) |j| value -= l[j][ii] * result[j];
        result[ii] = value / l[ii][ii];
    }
    return true;
}

fn precondition(n: usize, nnz: usize, v: []const i64, diagonal: *const [max_n]f64,
    r: *const [max_n]f64, z: *[max_n]f64) bool {
    const col = 4 + n;
    const val = col + nnz;
    var pre: [max_n]f64 = @splat(0.0);
    var product: [max_n]f64 = @splat(0.0);
    var middle: [max_n]f64 = @splat(0.0);
    var post_r: [max_n]f64 = @splat(0.0);
    var post: [max_n]f64 = @splat(0.0);
    for (0..n) |row| {
        var value = r[row];
        for (@intCast(v[3 + row])..@intCast(v[4 + row])) |edge| {
            const c: usize = @intCast(v[col + edge]);
            if (c < row) value -= @as(f64, @floatFromInt(v[val + edge])) / scale * pre[c];
        }
        pre[row] = value / diagonal[row];
    }
    matvec(n, nnz, v, &pre, &product);
    var coarse_rhs: [max_coarse]f64 = @splat(0.0);
    var coarse_x: [max_coarse]f64 = @splat(0.0);
    for (0..n) |row| coarse_rhs[row / 2] += r[row] - product[row];
    if (!coarseSolve(n, nnz, v, &coarse_rhs, &coarse_x)) return false;
    for (0..n) |row| middle[row] = pre[row] + coarse_x[row / 2];
    matvec(n, nnz, v, &middle, &product);
    for (0..n) |row| post_r[row] = r[row] - product[row];
    var ii = n;
    while (ii > 0) {
        ii -= 1;
        var value = post_r[ii];
        for (@intCast(v[3 + ii])..@intCast(v[4 + ii])) |edge| {
            const c: usize = @intCast(v[col + edge]);
            if (c > ii) value -= @as(f64, @floatFromInt(v[val + edge])) / scale * post[c];
        }
        post[ii] = value / diagonal[ii];
    }
    for (0..n) |row| z[row] = middle[row] + post[row];
    return true;
}

fn writeF64Le(output: [*]u8, offset: usize, value: f64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |byte| output[offset + byte] = @truncate(bits >> @intCast(8 * byte));
}

export fn hpcg_profile(input: ?[*]const i64, length: usize, output_opt: ?[*]u8, capacity: usize) i64 {
    if (input == null or length < 8 or length > 452) return -1;
    const v = input.?[0..length];
    var diagonal: [max_n]f64 = @splat(0.0);
    const parsed = valid(v, &diagonal) orelse return -1;
    const bytes = 8 * (parsed.n + 1);
    if (output_opt == null or capacity < bytes) return -2;
    const output = output_opt.?;
    const rhs = 4 + parsed.n + 2 * parsed.nnz;
    var b: [max_n]f64 = @splat(0.0);
    var x: [max_n]f64 = @splat(0.0);
    var r: [max_n]f64 = @splat(0.0);
    var z: [max_n]f64 = @splat(0.0);
    var p: [max_n]f64 = @splat(0.0);
    var q: [max_n]f64 = @splat(0.0);
    var ax: [max_n]f64 = @splat(0.0);
    var b2: f64 = 0;
    for (0..parsed.n) |i| { b[i] = @as(f64, @floatFromInt(v[rhs + i])) / scale; r[i] = b[i]; b2 += b[i] * b[i]; }
    if (b2 > 0) {
        if (!precondition(parsed.n, parsed.nnz, v, &diagonal, &r, &z)) return -1;
        p = z;
        var rho: f64 = 0;
        for (0..parsed.n) |i| rho += r[i] * z[i];
        if (!(rho > 0)) return -1;
        for (0..parsed.steps) |_| {
            matvec(parsed.n, parsed.nnz, v, &p, &q);
            var curvature: f64 = 0;
            for (0..parsed.n) |i| curvature += p[i] * q[i];
            if (!(curvature > 0)) return -1;
            const alpha = rho / curvature;
            for (0..parsed.n) |i| { x[i] += alpha * p[i]; r[i] -= alpha * q[i]; }
            var r2: f64 = 0;
            for (0..parsed.n) |i| r2 += r[i] * r[i];
            if (r2 <= b2 * 1.0e-28) break;
            var next_z: [max_n]f64 = @splat(0.0);
            if (!precondition(parsed.n, parsed.nnz, v, &diagonal, &r, &next_z)) return -1;
            var next_rho: f64 = 0;
            for (0..parsed.n) |i| next_rho += r[i] * next_z[i];
            if (!(next_rho > 0)) return -1;
            const beta = next_rho / rho;
            for (0..parsed.n) |i| { z[i] = next_z[i]; p[i] = z[i] + beta * p[i]; }
            rho = next_rho;
        }
    }
    matvec(parsed.n, parsed.nnz, v, &x, &ax);
    var residual2: f64 = 0;
    for (0..parsed.n) |i| { const e = b[i] - ax[i]; residual2 += e * e; writeF64Le(output, 8 * i, x[i]); }
    writeF64Le(output, 8 * parsed.n, @sqrt(residual2));
    return @intCast(bytes);
}
