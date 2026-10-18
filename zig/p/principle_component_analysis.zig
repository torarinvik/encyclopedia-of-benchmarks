const std = @import("std");
const MAX_OUTPUT: usize = 38;
const JACOBI_TOLERANCE: f64 = 1e-14;
const MIN_EIGEN_GAP: f64 = 1e-8;

fn diagonalize(a: *[16]f64, vectors: *[16]f64, n: usize) ?[4]f64 {
    for (0..n) |i| for (0..n) |j| { vectors[i * 4 + j] = if (i == j) 1.0 else 0.0; };
    var converged = false;
    for (0..65) |sweep| {
        var largest: f64 = 0;
        for (0..n) |p| for (p + 1..n) |q| { largest = @max(largest, @abs(a[p * 4 + q])); };
        if (largest <= JACOBI_TOLERANCE) { converged = true; break; }
        if (sweep == 64) break;
        for (0..n) |p| {
            for (p + 1..n) |q| {
                const apq = a[p * 4 + q];
                if (@abs(apq) <= JACOBI_TOLERANCE) continue;
                const tau = (a[q * 4 + q] - a[p * 4 + p]) / (2.0 * apq);
                const sign: f64 = if (tau >= 0) 1.0 else -1.0;
                const t = sign / (@abs(tau) + @sqrt(1.0 + tau * tau));
                const c = 1.0 / @sqrt(1.0 + t * t);
                const s = t * c;
                const app = a[p * 4 + p]; const aqq = a[q * 4 + q];
                a[p * 4 + p] = app - t * apq; a[q * 4 + q] = aqq + t * apq;
                a[p * 4 + q] = 0; a[q * 4 + p] = 0;
                for (0..n) |r| {
                    if (r != p and r != q) {
                        const arp = a[r * 4 + p]; const arq = a[r * 4 + q];
                        a[r * 4 + p] = c * arp - s * arq; a[p * 4 + r] = a[r * 4 + p];
                        a[r * 4 + q] = s * arp + c * arq; a[q * 4 + r] = a[r * 4 + q];
                    }
                    const vrp = vectors[r * 4 + p]; const vrq = vectors[r * 4 + q];
                    vectors[r * 4 + p] = c * vrp - s * vrq;
                    vectors[r * 4 + q] = s * vrp + c * vrq;
                }
            }
        }
    }
    if (!converged) return null;
    var values = [_]f64{0} ** 4;
    for (0..n) |i| values[i] = a[i * 4 + i];
    for (0..n) |i| for (i + 1..n) |j| {
        if (values[j] > values[i]) {
            std.mem.swap(f64, &values[i], &values[j]);
            for (0..n) |r| std.mem.swap(f64, &vectors[r * 4 + i], &vectors[r * 4 + j]);
        }
    };
    return values;
}

export fn principle_component_analysis(input: ?[*]const f64, input_length: usize,
    output: ?[*]f64, capacity: usize) i64 {
    const values = input orelse return -1;
    if (input_length < 3 or input_length > 35) return -1;
    for (0..input_length) |i| if (!std.math.isFinite(values[i])) return -1;
    for (0..3) |i| if (@trunc(values[i]) != values[i]) return -1;
    if (values[0] < 3 or values[0] > 8 or values[1] < 2 or values[1] > 4 or values[2] < 1 or values[2] > 4) return -1;
    const samples: usize = @intFromFloat(values[0]);
    const features: usize = @intFromFloat(values[1]);
    const components: usize = @intFromFloat(values[2]);
    if (samples <= features or components > features or input_length != 3 + samples * features) return -1;
    var rows = [_]f64{0} ** 32; var means = [_]f64{0} ** 4;
    for (0..samples) |r| for (0..features) |c| {
        const x = values[3 + r * features + c];
        if (@trunc(x) != x or x < -9 or x > 9) return -1;
        rows[r * 4 + c] = x; means[c] += x;
    };
    for (0..features) |c| means[c] /= @floatFromInt(samples);
    var variances = [_]f64{0} ** 4;
    for (0..samples) |r| for (0..features) |c| {
        const d = rows[r * 4 + c] - means[c]; variances[c] += d * d;
    };
    var scales = [_]f64{0} ** 4;
    for (0..features) |c| {
        variances[c] /= @floatFromInt(samples);
        if (!(variances[c] > 0) or !std.math.isFinite(variances[c])) return -1;
        scales[c] = @sqrt(variances[c]);
    }
    var z = [_]f64{0} ** 32; var pca_means = [_]f64{0} ** 4;
    for (0..samples) |r| for (0..features) |c| {
        z[r * 4 + c] = (rows[r * 4 + c] - means[c]) / scales[c];
        pca_means[c] += z[r * 4 + c];
    };
    for (0..features) |c| pca_means[c] /= @floatFromInt(samples);
    var centered = [_]f64{0} ** 32;
    for (0..samples) |r| for (0..features) |c| centered[r * 4 + c] = z[r * 4 + c] - pca_means[c];
    var covariance = [_]f64{0} ** 16;
    for (0..features) |i| for (i..features) |j| {
        var sum: f64 = 0;
        for (0..samples) |r| sum += centered[r * 4 + i] * centered[r * 4 + j];
        covariance[i * 4 + j] = sum / @floatFromInt(samples - 1);
        covariance[j * 4 + i] = covariance[i * 4 + j];
    };
    var vectors = [_]f64{0} ** 16;
    const eigenvalues = diagonalize(&covariance, &vectors, features) orelse return -1;
    for (0..features) |i| {
        if (!(eigenvalues[i] > 0) or !std.math.isFinite(eigenvalues[i]) or
            (i + 1 < features and eigenvalues[i] - eigenvalues[i + 1] <= MIN_EIGEN_GAP)) return -1;
    }
    var total: f64 = 0;
    for (0..features) |i| total += eigenvalues[i];
    if (!(total > 0) or !std.math.isFinite(total)) return -1;
    var scores = [_]f64{0} ** 32;
    for (0..components) |k| {
        for (0..samples) |r| for (0..features) |c| scores[k * 8 + r] += centered[r * 4 + c] * vectors[c * 4 + k];
        var pivot: usize = 0;
        for (1..samples) |r| if (@abs(scores[k * 8 + r]) > @abs(scores[k * 8 + pivot])) { pivot = r; };
        if (scores[k * 8 + pivot] < 0) for (0..samples) |r| { scores[k * 8 + r] = -scores[k * 8 + r]; };
    }
    var staged = [_]f64{0} ** MAX_OUTPUT;
    staged[0] = @floatFromInt(samples); staged[1] = @floatFromInt(components);
    var pos: usize = 2;
    for (0..samples) |r| for (0..components) |k| { staged[pos] = scores[k * 8 + r]; pos += 1; };
    for (0..components) |k| { staged[pos] = eigenvalues[k] / total; pos += 1; }
    for (staged[0..pos]) |x| if (!std.math.isFinite(x)) return -1;
    const out = output orelse return -2;
    if (capacity < pos) return -2;
    @memcpy(out[0..pos], staged[0..pos]);
    return @intCast(pos);
}
