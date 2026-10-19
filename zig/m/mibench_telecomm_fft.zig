// Based on Don Cross <dcross@intersrv.com>'s public-domain fft_float (intersrv.com/~dcross/fft.html).
// Modified for the bounded float64-slice ABI; binary32 work-array semantics retained.
fn transform(real: *[16]f32, imag: *[16]f32, n: usize, inverse: bool) void {
    var bits: usize = 0;
    var size = n;
    while (size > 1) : (size >>= 1) bits += 1;
    for (0..n) |i| {
        var source = i;
        var reverse: usize = 0;
        for (0..bits) |_| { reverse = (reverse << 1) | (source & 1); source >>= 1; }
        if (i < reverse) {
            const tr = real.*[i]; real.*[i] = real.*[reverse]; real.*[reverse] = tr;
            const ti = imag.*[i]; imag.*[i] = imag.*[reverse]; imag.*[reverse] = ti;
        }
    }
    const angle_num = (if (inverse) @as(f64, -2.0) else 2.0) * 3.14159265358979323846;
    var block_end: usize = 1;
    var block: usize = 2;
    while (block <= n) : (block *= 2) {
        const delta = angle_num / @as(f64, @floatFromInt(block));
        const sm2 = @sin(-2.0 * delta); const sm1 = @sin(-delta);
        const cm2 = @cos(-2.0 * delta); const cm1 = @cos(-delta); const w = 2.0 * cm1;
        var start: usize = 0;
        while (start < n) : (start += block) {
            var ar2 = cm2; var ar1 = cm1; var ai2 = sm2; var ai1 = sm1;
            for (0..block_end) |offset| {
                const ar0 = w * ar1 - ar2; ar2 = ar1; ar1 = ar0;
                const ai0 = w * ai1 - ai2; ai2 = ai1; ai1 = ai0;
                const first = start + offset; const second = first + block_end;
                const tr = ar0 * @as(f64, real.*[second]) - ai0 * @as(f64, imag.*[second]);
                const ti = ar0 * @as(f64, imag.*[second]) + ai0 * @as(f64, real.*[second]);
                real.*[second] = @floatCast(@as(f64, real.*[first]) - tr);
                imag.*[second] = @floatCast(@as(f64, imag.*[first]) - ti);
                real.*[first] = @floatCast(@as(f64, real.*[first]) + tr);
                imag.*[first] = @floatCast(@as(f64, imag.*[first]) + ti);
            }
        }
        block_end = block;
    }
    if (inverse) for (0..n) |i| {
        const dn: f64 = @floatFromInt(n);
        real.*[i] = @floatCast(@as(f64, real.*[i]) / dn);
        imag.*[i] = @floatCast(@as(f64, imag.*[i]) / dn);
    };
}

export fn mibench_telecomm_fft(input: ?[*]const f64, length: usize, output: ?[*]f64, capacity: usize) i64 {
    if (input == null or length < 6 or length > 34) return -1;
    const values = input.?[0..length];
    const nd = values[0]; const inverse = values[1];
    if (nd != nd or inverse != inverse or @trunc(nd) != nd or @trunc(inverse) != inverse
        or nd < 2 or nd > 16 or (inverse != 0 and inverse != 1)) return -1;
    const n: usize = @intFromFloat(nd);
    if ((n & (n - 1)) != 0 or length != 2 + 2 * n) return -1;
    for (values[2..]) |sample| if (sample != sample or sample < -8 or sample > 8) return -1;
    const required = 2 * n;
    if (output == null or capacity < required) return -2;
    var real: [16]f32 = @splat(0); var imag: [16]f32 = @splat(0);
    for (0..n) |i| { real[i] = @floatCast(values[2 + i]); imag[i] = @floatCast(values[2 + n + i]); }
    transform(&real, &imag, n, inverse != 0);
    var staged: [32]f64 = @splat(0);
    for (0..n) |i| { staged[2 * i] = real[i]; staged[2 * i + 1] = imag[i]; }
    for (0..required) |i| output.?[i] = staged[i];
    return @intCast(required);
}
