/// Peak signal-to-noise ratio on the shared non-identical 8-bit image domain.
export fn peak_signal_to_noise_ratio(v: [*]const i64, n: usize) f64 {
    if (n < 3 or n > 129) return -1e300;
    if (v[0] < 1 or v[0] > 64 or n != 1 + 2 * @as(usize, @intCast(v[0]))) return -1e300;
    const count: usize = @intCast(v[0]);
    var sum: f64 = 0.0;
    for (0..count) |i| {
        const a = v[i + 1]; const b = v[i + 1 + count];
        if (a < 0 or a > 255 or b < 0 or b > 255) return -1e300;
        if (a - b < -15 or a - b > 15) return -1e300;
        const d = @as(f64, @floatFromInt(a)) - @as(f64, @floatFromInt(b));
        sum += d * d;
    }
    const mse = sum / @as(f64, @floatFromInt(count));
    if (mse == 0.0) return -1e300;
    return 20.0 * @log10(255.0 / @sqrt(mse));
}
