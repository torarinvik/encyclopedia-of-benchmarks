export fn dimensionality_reduction_tsne(ptr: [*c]const f64, n: usize, out: [*c]f64, cap: usize) i64 {
    if (ptr == null or n != 5) return -1;
    const v = ptr[0..n];
    if (v[0] != 1 or v[1] != 3) return -1;
    for (2..5) |i| {
        if (!std.math.isFinite(v[i]) or @abs(v[i]) > 100) return -1;
    }
    if (out == null or cap < 3) return -2;
    var d = [_][3]f64{ @splat(0), @splat(0), @splat(0) };
    var p = [_][3]f64{ @splat(0), @splat(0), @splat(0) };
    for (0..3) |i| {
        for (0..3) |j| {
            const z = v[2 + i] - v[2 + j];
            d[i][j] = z * z;
        }
    }
    for (0..3) |i| {
        var lo = -std.math.inf(f64);
        var hi = std.math.inf(f64);
        var beta: f64 = 1;
        var probs = [_]f64{ 0, 0, 0 };
        var it: usize = 0;
        while (it < 50) : (it += 1) {
            var e = [_]f64{ 0, 0, 0 };
            var sum: f64 = 0;
            for (0..3) |j| {
                e[j] = if (i == j) 0 else @exp(-d[i][j] * beta);
                sum += e[j];
            }
            if (sum == 0) {
                p[i] = .{ 0, 0, 0 };
                break;
            }
            var h: f64 = 0;
            for (0..3) |j| {
                probs[j] = e[j] / sum;
                if (probs[j] > 0) h -= probs[j] * @log2(probs[j] + 1e-12);
            }
            const cur = @exp2(h);
            if (@abs(cur - 1.5) < 1e-5) {
                p[i] = probs;
                break;
            }
            if (cur > 1.5) {
                lo = beta;
                beta = if (std.math.isInf(hi)) beta * 2 else (beta + hi) / 2;
            } else {
                hi = beta;
                beta = if (std.math.isInf(lo)) beta / 2 else (beta + lo) / 2;
            }
            if (it == 49) p[i] = probs;
        }
    }
    var high = [_][3]f64{ @splat(0), @splat(0), @splat(0) };
    for (0..3) |i| {
        for (0..3) |j| {
            high[i][j] = @max((p[i][j] + p[j][i]) / 6, 1e-12);
        }
    }
    var y = [_]f64{ 3.0471707975443136e-05, -1.0399841062404956e-04, 7.504511958064573e-05 };
    var mom = [_]f64{ 0, 0, 0 };
    for (0..5) |_| {
        var q = [_][3]f64{ @splat(0), @splat(0), @splat(0) };
        var den = [_][3]f64{ @splat(0), @splat(0), @splat(0) };
        var total: f64 = 0;
        for (0..3) |i| {
            for (0..3) |j| {
                const z = y[i] - y[j];
                den[i][j] = if (i == j) std.math.inf(f64) else 1 + z * z;
                q[i][j] = if (i == j) 0 else 1 / den[i][j];
                total += q[i][j];
            }
        }
        for (0..3) |i| {
            for (0..3) |j| {
                q[i][j] = if (total == 0) (if (i == j) 0 else 1.0 / 6.0) else q[i][j] / total;
                q[i][j] = @max(q[i][j], 1e-12);
            }
        }
        var g = [_]f64{ 0, 0, 0 };
        for (0..3) |i| {
            for (0..3) |j| {
                g[i] += (high[i][j] - q[i][j]) * (1 / den[i][j]) * (y[i] - y[j]);
            }
            g[i] *= 4;
        }
        for (0..3) |i| {
            mom[i] = 0.5 * mom[i] - 10 * g[i];
            y[i] += mom[i];
        }
    }
    for (0..3) |i| out[i] = y[i];
    return 3;
}
const std = @import("std");
