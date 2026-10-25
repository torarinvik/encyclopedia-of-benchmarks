// Rodinia particlefilter_naive one-transition profile; full notice: benchmarks/r/rodinia_particlefilter_naive/LICENSE.txt.
const std = @import("std");
const SCALE: f64 = 1_000_000.0;

fn roundAway(value: f64) i64 {
    const scaled = value * 1000.0;
    if (scaled < 0.0) return -@as(i64, @intFromFloat(@floor(-scaled + 0.5)));
    return @intFromFloat(@floor(scaled + 0.5));
}

pub export fn rodinia_particlefilter_naive(input: ?[*]const i64, length: usize) i64 {
    const v = input orelse return -1;
    if (length < 8 or length > 35) return -1;
    const n_raw = v[0]; const samples_raw = v[1]; const offset_raw = v[2];
    if (n_raw < 1 or n_raw > 4 or samples_raw < 1 or samples_raw > 4) return -1;
    const n: usize = @intCast(n_raw); const samples: usize = @intCast(samples_raw);
    if (length != 3 + n * (4 + samples) or offset_raw < 0 or offset_raw >= 1_000_000 or offset_raw * n_raw >= 1_000_000) return -1;
    var x = [_]f64{0} ** 4; var y = [_]f64{0} ** 4;
    var moved_x = [_]f64{0} ** 4; var moved_y = [_]f64{0} ** 4;
    var weights = [_]f64{0} ** 4; var cdf = [_]f64{0} ** 4;
    var resampled_x = [_]f64{0} ** 4; var resampled_y = [_]f64{0} ** 4;
    for (0..n) |i| {
        const at = 3 + i * (4 + samples);
        const xr = v[at]; const yr = v[at + 1]; const nxr = v[at + 2]; const nyr = v[at + 3];
        if (xr < -100_000_000 or xr > 100_000_000 or yr < -100_000_000 or yr > 100_000_000 or nxr < -2_000_000 or nxr > 2_000_000 or nyr < -2_000_000 or nyr > 2_000_000) return -1;
        x[i] = @as(f64, @floatFromInt(xr)) / SCALE; y[i] = @as(f64, @floatFromInt(yr)) / SCALE;
        moved_x[i] = x[i] + 1.0 + 5.0 * (@as(f64, @floatFromInt(nxr)) / SCALE);
        moved_y[i] = y[i] - 2.0 + 2.0 * (@as(f64, @floatFromInt(nyr)) / SCALE);
        var likelihood_sum: f64 = 0.0;
        for (0..samples) |j| {
            const intensity = v[at + 4 + j]; if (intensity < 0 or intensity > 255) return -1;
            const foreground = @as(f64, @floatFromInt(intensity - 100));
            const background = @as(f64, @floatFromInt(intensity - 228));
            likelihood_sum += (foreground * foreground - background * background) / 50.0;
        }
        const likelihood = likelihood_sum / @as(f64, @floatFromInt(samples));
        weights[i] = (1.0 / @as(f64, @floatFromInt(n))) * @exp(likelihood);
    }
    var weight_sum: f64 = 0.0; for (0..n) |i| weight_sum += weights[i];
    if (!std.math.isFinite(weight_sum) or weight_sum <= 0.0) return -1;
    for (0..n) |i| weights[i] /= weight_sum;
    var estimate_x: f64 = 0.0; var estimate_y: f64 = 0.0;
    for (0..n) |i| { estimate_x += moved_x[i] * weights[i]; estimate_y += moved_y[i] * weights[i]; }
    cdf[0] = weights[0]; for (1..n) |i| cdf[i] = weights[i] + cdf[i - 1];
    const offset = @as(f64, @floatFromInt(offset_raw)) / SCALE;
    for (0..n) |i| {
        const u = offset + @as(f64, @floatFromInt(i)) / @as(f64, @floatFromInt(n));
        var selected = n - 1;
        for (0..n) |j| { if (cdf[j] >= u) { selected = j; break; } }
        resampled_x[i] = moved_x[selected]; resampled_y[i] = moved_y[selected];
    }
    var checksum = roundAway(estimate_x) + 2 * roundAway(estimate_y);
    for (0..n) |i| checksum += @as(i64, @intCast(2 * i + 3)) * roundAway(resampled_x[i]) + @as(i64, @intCast(2 * i + 4)) * roundAway(resampled_y[i]);
    return checksum;
}
