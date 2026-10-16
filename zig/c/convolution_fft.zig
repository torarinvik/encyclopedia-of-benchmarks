const MAX_INPUT_LENGTH: usize = 131;
const PI: f64 = 3.14159265358979323846264338327950288;

fn writeF64Le(output: [*]u8, offset: usize, value: f64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |byte| output[offset + byte] = @truncate(bits >> @intCast(byte * 8));
}

fn transform(real: *[128]f64, imag: *[128]f64, n: usize, inverse: bool) void {
    var reverse: usize = 0;
    for (1..n) |position| {
        var bit = n >> 1;
        while ((reverse & bit) != 0) { reverse ^= bit; bit >>= 1; }
        reverse ^= bit;
        if (position < reverse) {
            const temporary = real.*[position]; real.*[position] = real.*[reverse]; real.*[reverse] = temporary;
            const imag_temporary = imag.*[position]; imag.*[position] = imag.*[reverse]; imag.*[reverse] = imag_temporary;
        }
    }
    var block: usize = 2;
    while (block <= n) : (block *= 2) {
        const direction: f64 = if (inverse) -1.0 else 1.0;
        const angle = -2.0 * PI / @as(f64, @floatFromInt(block)) * direction;
        const step_real, const step_imag = .{@cos(angle), @sin(angle)};
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
    if (inverse) {
        for (0..n) |index| {
            real.*[index] /= @floatFromInt(n);
            imag.*[index] /= @floatFromInt(n);
        }
    }
}

export fn convolution_fft(input: ?[*]const i64, length: usize, output: ?[*]u8, capacity: usize) i64 {
    if (input == null or length < 4 or length > MAX_INPUT_LENGTH) return -1;
    const values = input.?[0..length];
    const raw_a = values[0]; const raw_b = values[1];
    if (raw_a < 1 or raw_a > 64 or raw_b < 1 or raw_b > 64) return -1;
    const a_count: usize = @intCast(raw_a); const b_count: usize = @intCast(raw_b);
    if (length != 2 + a_count + b_count) return -1;
    for (values[2..]) |sample| if (sample < -64 or sample > 64) return -1;
    const result_count = a_count + b_count - 1;
    const byte_count = result_count * 16;
    if (output == null or capacity < byte_count) return -2;
    var fft_length: usize = 1;
    while (fft_length < result_count) : (fft_length *= 2) {}
    var a_real: [128]f64 = @splat(0.0); var a_imag: [128]f64 = @splat(0.0);
    var b_real: [128]f64 = @splat(0.0); var b_imag: [128]f64 = @splat(0.0);
    var product_real: [128]f64 = @splat(0.0); var product_imag: [128]f64 = @splat(0.0);
    for (0..a_count) |index| a_real[index] = @as(f64, @floatFromInt(values[index + 2])) / 16.0;
    for (0..b_count) |index| b_real[index] = @as(f64, @floatFromInt(values[a_count + index + 2])) / 16.0;
    transform(&a_real, &a_imag, fft_length, false);
    transform(&b_real, &b_imag, fft_length, false);
    for (0..fft_length) |index| {
        product_real[index] = a_real[index] * b_real[index] - a_imag[index] * b_imag[index];
        product_imag[index] = a_real[index] * b_imag[index] + a_imag[index] * b_real[index];
    }
    transform(&product_real, &product_imag, fft_length, true);
    const result = output.?;
    for (0..result_count) |index| {
        writeF64Le(result, index * 16, product_real[index]);
        writeF64Le(result, index * 16 + 8, product_imag[index]);
    }
    return @intCast(byte_count);
}
