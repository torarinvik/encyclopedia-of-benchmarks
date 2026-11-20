const MAX_N: usize = 32;
const SCALE: i64 = 256;
const INVALID_RESULT: f64 = -1.0e300;
const TAU: f64 = 6.283185307179586476925286766559005768;

fn fft(real: []f64, imag: []f64, n: usize, inverse: bool) void {
    var j: usize = 0;
    var i: usize = 1;
    while (i < n) : (i += 1) {
        var bit = n >> 1;
        while ((j & bit) != 0) { j ^= bit; bit >>= 1; }
        j ^= bit;
        if (i < j) {
            const tr = real[i]; real[i] = real[j]; real[j] = tr;
            const ti = imag[i]; imag[i] = imag[j]; imag[j] = ti;
        }
    }
    var width: usize = 2;
    while (width <= n) : (width <<= 1) {
        const direction: f64 = if (inverse) 1.0 else -1.0;
        const angle = direction * TAU / @as(f64, @floatFromInt(width));
        const step_real = @cos(angle);
        const step_imag = @sin(angle);
        const half = width >> 1;
        var start: usize = 0;
        while (start < n) : (start += width) {
            var twiddle_real: f64 = 1.0;
            var twiddle_imag: f64 = 0.0;
            for (0..half) |offset| {
                const even = start + offset;
                const odd = even + half;
                const odd_real = real[odd] * twiddle_real - imag[odd] * twiddle_imag;
                const odd_imag = real[odd] * twiddle_imag + imag[odd] * twiddle_real;
                real[odd] = real[even] - odd_real;
                imag[odd] = imag[even] - odd_imag;
                real[even] += odd_real;
                imag[even] += odd_imag;
                const next_real = twiddle_real * step_real - twiddle_imag * step_imag;
                twiddle_imag = twiddle_real * step_imag + twiddle_imag * step_real;
                twiddle_real = next_real;
            }
        }
    }
    if (inverse) {
        for (0..n) |index| {
            real[index] /= @as(f64, @floatFromInt(n));
            imag[index] /= @as(f64, @floatFromInt(n));
        }
    }
}

pub export fn quantum_spectral_energy_expectation(input: ?[*]const i64, length: usize) f64 {
    if (input == null or length < 1 or length > 98) return INVALID_RESULT;
    const values = input.?[0..length];
    const n_value = values[0];
    if (n_value < 2 or n_value > @as(i64, @intCast(MAX_N)) or
        (n_value & (n_value - 1)) != 0) return INVALID_RESULT;
    const n: usize = @intCast(n_value);
    if (length != 1 + 3 * n) return INVALID_RESULT;
    var norm: i64 = 0;
    for (0..n) |index| {
        const potential = values[1 + index];
        const real_q = values[1 + n + index];
        const imag_q = values[1 + 2 * n + index];
        if (potential < -2048 or potential > 2048 or real_q < -2048 or real_q > 2048 or
            imag_q < -2048 or imag_q > 2048) return INVALID_RESULT;
        norm += real_q * real_q + imag_q * imag_q;
    }
    if (norm != SCALE * SCALE * n_value) return INVALID_RESULT;

    var real: [MAX_N]f64 = [_]f64{0.0} ** MAX_N;
    var imag: [MAX_N]f64 = [_]f64{0.0} ** MAX_N;
    for (0..n) |index| {
        real[index] = @as(f64, @floatFromInt(values[1 + n + index])) / @as(f64, @floatFromInt(SCALE));
        imag[index] = @as(f64, @floatFromInt(values[1 + 2 * n + index])) / @as(f64, @floatFromInt(SCALE));
    }
    fft(real[0..n], imag[0..n], n, false);
    for (0..n) |index| {
        const frequency: i64 = if (index <= n / 2) @intCast(index) else @as(i64, @intCast(index)) - n_value;
        const wave_number = TAU * @as(f64, @floatFromInt(frequency));
        const multiplier = 0.5 * wave_number * wave_number;
        real[index] *= multiplier;
        imag[index] *= multiplier;
    }
    fft(real[0..n], imag[0..n], n, true);
    var total: f64 = 0.0;
    for (0..n) |index| {
        const psi_real = @as(f64, @floatFromInt(values[1 + n + index])) / @as(f64, @floatFromInt(SCALE));
        const psi_imag = @as(f64, @floatFromInt(values[1 + 2 * n + index])) / @as(f64, @floatFromInt(SCALE));
        const potential = @as(f64, @floatFromInt(values[1 + index])) / @as(f64, @floatFromInt(SCALE));
        total += psi_real * (real[index] + potential * psi_real)
            + psi_imag * (imag[index] + potential * psi_imag);
    }
    return total / @as(f64, @floatFromInt(n));
}
