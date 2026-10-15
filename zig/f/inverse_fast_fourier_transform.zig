fn storeI64Le(output: [*]u8, offset: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |byte| output[offset + byte] = @intCast((bits >> @intCast(byte * 8)) & 0xff);
}
fn quantize(value: f64) i64 {
    const scaled = value * 1_000_000.0;
    return @intFromFloat(if (scaled >= 0.0) scaled + 0.5 else scaled - 0.5);
}
fn transform(real: *[64]f64, imag: *[64]f64, n: usize) void {
    var reverse: usize = 0;
    for (1..n) |position| {
        var bit = n >> 1;
        while ((reverse & bit) != 0) { reverse ^= bit; bit >>= 1; }
        reverse ^= bit;
        if (position < reverse) { const temporary = real.*[position]; real.*[position] = real.*[reverse]; real.*[reverse] = temporary; const imag_temp = imag.*[position]; imag.*[position] = imag.*[reverse]; imag.*[reverse] = imag_temp; }
    }
    var block: usize = 2;
    while (block <= n) : (block *= 2) {
        const angle = 6.283185307179586476925286766559 / @as(f64, @floatFromInt(block));
        const step_real, const step_imag = .{@cos(angle), -@sin(angle)};
        var start: usize = 0;
        while (start < n) : (start += block) {
            var weight_real: f64 = 1.0; var weight_imag: f64 = 0.0;
            for (0..block / 2) |offset| {
                const first = start + offset; const second = first + block / 2;
                const product_real = weight_real * real.*[second] - weight_imag * imag.*[second];
                const product_imag = weight_real * imag.*[second] + weight_imag * real.*[second];
                const first_real = real.*[first]; const first_imag = imag.*[first];
                real.*[first] = first_real + product_real; imag.*[first] = first_imag + product_imag;
                real.*[second] = first_real - product_real; imag.*[second] = first_imag - product_imag;
                const next_real = weight_real * step_real - weight_imag * step_imag;
                weight_imag = weight_real * step_imag + weight_imag * step_real; weight_real = next_real;
            }
        }
    }
}
export fn inverse_fast_fourier_transform(values: ?[*]const i64, length: usize, output: ?[*]u8, output_capacity: usize) i64 {
    if (values == null or length < 3 or length > 129) return -1;
    const input = values.?[0..length]; const raw_n = input[0];
    if (raw_n < 1 or raw_n > 64 or (raw_n & (raw_n - 1)) != 0) return -1;
    const n: usize = @intCast(raw_n);
    if (length != 1 + 2 * n) return -1;
    for (input[1..]) |value| if (value < -1000 or value > 1000) return -1;
    const byte_count = 8 * n;
    if (output == null or output_capacity < byte_count) return -2;
    var real: [64]f64 = @splat(0.0); var imag: [64]f64 = @splat(0.0);
    for (0..n) |index| { real[index] = @floatFromInt(input[2 * index + 1]); imag[index] = @floatFromInt(input[2 * index + 2]); }
    transform(&real, &imag, n);
    for (0..n) |index| storeI64Le(output.?[0..].ptr, index * 8, quantize(real[index] / @as(f64, @floatFromInt(n))));
    return @intCast(byte_count);
}
