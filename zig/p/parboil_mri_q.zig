const MAX_INPUT_LENGTH: usize = 24;
const PI_X_2: f32 = 6.2831853071795864769252867665590058;

fn decodeComponent(raw: i64) f32 { return @as(f32, @floatFromInt(raw)) / 1_000_000.0; }

fn quantizeQ(value: f32) i32 {
    const scaled = value * 1_000.0;
    const magnitude = @abs(scaled);
    var whole: i32 = @intFromFloat(magnitude);
    const fraction = magnitude - @as(f32, @floatFromInt(whole));
    if (fraction >= 0.5) whole += 1;
    return if (scaled < 0.0) -whole else whole;
}

fn writeI32Le(output: [*c]u8, offset: usize, value: i32) void {
    const bits: u32 = @bitCast(value);
    output[offset] = @truncate(bits);
    output[offset + 1] = @truncate(bits >> 8);
    output[offset + 2] = @truncate(bits >> 16);
    output[offset + 3] = @truncate(bits >> 24);
}

// Clean-room Parboil MRI-Q profile; Illinois Open Source License in package docs.
pub export fn parboil_mri_q(input: [*c]const i64, input_length: usize,
    output: [*c]u8, output_capacity: usize) i64 {
    if (input == null or input_length < 9 or input_length > MAX_INPUT_LENGTH) return -1;
    const count_value = input[0];
    if (count_value < 1 or count_value > 4) return -1;
    const count: usize = @intCast(count_value);
    if (input_length != 4 + 5 * count) return -1;
    for (1..input_length) |i| if (input[i] < -1_000_000 or input[i] > 1_000_000) return -1;
    if (output == null or output_capacity < 8) return -2;

    const x = decodeComponent(input[1]);
    const y = decodeComponent(input[2]);
    const z = decodeComponent(input[3]);
    var phi_magnitudes = [_]f32{0.0} ** 4;
    for (0..count) |k| {
        const offset = 4 + 5 * k;
        const phi_real = decodeComponent(input[offset + 3]);
        const phi_imag = decodeComponent(input[offset + 4]);
        const real_square = phi_real * phi_real;
        const imag_square = phi_imag * phi_imag;
        phi_magnitudes[k] = real_square + imag_square;
    }
    var qr: f32 = 0.0;
    var qi: f32 = 0.0;
    for (0..count) |k| {
        const offset = 4 + 5 * k;
        const kx = decodeComponent(input[offset]);
        const ky = decodeComponent(input[offset + 1]);
        const kz = decodeComponent(input[offset + 2]);
        const kx_x = kx * x;
        const ky_y = ky * y;
        const kz_z = kz * z;
        const xy = kx_x + ky_y;
        const xyz = xy + kz_z;
        const phase = PI_X_2 * xyz;
        const cos_phase: f32 = @cos(phase);
        const sin_phase: f32 = @sin(phase);
        const qr_term = phi_magnitudes[k] * cos_phase;
        const qi_term = phi_magnitudes[k] * sin_phase;
        qr = qr + qr_term;
        qi = qi + qi_term;
    }
    writeI32Le(output, 0, quantizeQ(qr));
    writeI32Le(output, 4, quantizeQ(qi));
    return 8;
}
