const std = @import("std");

const MAX_INPUT: usize = 2054;
const MAX_AUDIO: usize = 2048;
const MAX_FFT: usize = 1024;
const MAX_FRAMES: usize = 257;
const MAX_MELS: usize = 16;
const MAX_DCTS: usize = 40;
const PI: f64 = 3.14159265358979323846264338327950288;

fn fft(real: *[MAX_FFT]f64, imag: *[MAX_FFT]f64, n: usize) void {
    var reversed: usize = 0;
    var position: usize = 1;
    while (position < n) : (position += 1) {
        var bit = n >> 1;
        while ((reversed & bit) != 0) {
            reversed ^= bit;
            bit >>= 1;
        }
        reversed ^= bit;
        if (position < reversed) {
            std.mem.swap(f64, &real[position], &real[reversed]);
            std.mem.swap(f64, &imag[position], &imag[reversed]);
        }
    }
    var block_size: usize = 2;
    while (block_size <= n) : (block_size *= 2) {
        const angle = -2.0 * PI / @as(f64, @floatFromInt(block_size));
        const step_real = @cos(angle);
        const step_imag = @sin(angle);
        const half = block_size >> 1;
        var start: usize = 0;
        while (start < n) : (start += block_size) {
            var weight_real: f64 = 1.0;
            var weight_imag: f64 = 0.0;
            for (0..half) |offset| {
                const even = start + offset;
                const odd = even + half;
                const product_real = weight_real * real[odd] - weight_imag * imag[odd];
                const product_imag = weight_real * imag[odd] + weight_imag * real[odd];
                real[odd] = real[even] - product_real;
                imag[odd] = imag[even] - product_imag;
                real[even] += product_real;
                imag[even] += product_imag;
                const next_real = weight_real * step_real - weight_imag * step_imag;
                weight_imag = weight_real * step_imag + weight_imag * step_real;
                weight_real = next_real;
            }
        }
    }
}

fn hzToMel(hz: f64) f64 {
    return 2595.0 * @log10(1.0 + hz / 700.0);
}

fn melToHz(mel: f64) f64 {
    return 700.0 * (std.math.pow(f64, 10.0, mel / 2595.0) - 1.0);
}

fn putF64Le(output: [*]u8, offset: usize, value: f64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |byte| output[offset + byte] = @truncate(bits >> @intCast(byte * 8));
}

export fn mfcc(input: ?[*]const i64, length: usize, output: ?[*]u8, capacity: usize) i64 {
    if (input == null or length < 6 or length > MAX_INPUT) return -1;
    const values = input.?;
    const count_value = values[0];
    const sample_rate_value = values[1];
    const hop_ms_value = values[2];
    const fft_value = values[3];
    const mel_value = values[4];
    const dct_value = values[5];
    if (count_value < 33 or count_value > 2048 or length != @as(usize, @intCast(count_value + 6))) return -1;
    if (sample_rate_value < 8000 or sample_rate_value > 48000 or hop_ms_value < 1 or hop_ms_value > 50) return -1;
    if (fft_value != 64 and fft_value != 128 and fft_value != 256 and fft_value != 512 and fft_value != 1024) return -1;
    if (mel_value < 2 or mel_value > 16 or dct_value < 1 or dct_value > 40) return -1;

    const count: usize = @intCast(count_value);
    const sample_rate: usize = @intCast(sample_rate_value);
    const fft_size: usize = @intCast(fft_value);
    const mel_count: usize = @intCast(mel_value);
    const dct_count: usize = @intCast(dct_value);
    if (count < fft_size / 2 + 1) return -1;
    const hop_numerator = sample_rate * @as(usize, @intCast(hop_ms_value));
    var hop = hop_numerator / 1000;
    const hop_remainder = hop_numerator % 1000;
    if (hop_remainder > 500 or (hop_remainder == 500 and hop % 2 == 1)) hop += 1;
    if (hop == 0) return -1;

    var audio: [MAX_AUDIO]f64 = undefined;
    var peak: f64 = 0.0;
    for (0..count) |index| {
        const sample: f64 = @bitCast(values[6 + index]);
        if (sample != sample or @abs(sample) > 1_000_000.0) return -1;
        audio[index] = sample;
        peak = @max(peak, @abs(sample));
    }
    if (peak == 0.0) return -1;
    for (0..count) |index| audio[index] /= peak;

    const pad = fft_size / 2;
    const frames = count / hop + 1;
    const bin_count = fft_size / 2 + 1;
    if (frames > MAX_FRAMES) return -1;
    var padded: [MAX_AUDIO + MAX_FFT]f64 = undefined;
    for (0..pad) |index| padded[index] = audio[pad - index];
    for (0..count) |index| padded[pad + index] = audio[index];
    for (0..pad) |index| padded[pad + count + index] = audio[count - 2 - index];

    var frequencies: [MAX_MELS + 2]f64 = undefined;
    var bins: [MAX_MELS + 2]usize = undefined;
    const mel_low = hzToMel(0.0);
    const mel_high = hzToMel(@as(f64, @floatFromInt(sample_rate / 2)));
    for (0..mel_count + 2) |index| {
        const mel = mel_low + (mel_high - mel_low) * @as(f64, @floatFromInt(index)) /
            @as(f64, @floatFromInt(mel_count + 1));
        frequencies[index] = melToHz(mel);
        const bin = @floor(@as(f64, @floatFromInt(fft_size + 1)) /
            @as(f64, @floatFromInt(sample_rate)) * frequencies[index]);
        if (bin < 0.0 or bin >= @as(f64, @floatFromInt(bin_count))) return -1;
        bins[index] = @intFromFloat(bin);
    }
    for (0..mel_count + 1) |index| if (bins[index] >= bins[index + 1]) return -1;
    var norms: [MAX_MELS]f64 = undefined;
    for (0..mel_count) |index| {
        norms[index] = 2.0 / (frequencies[index + 2] - frequencies[index]);
        if (norms[index] != norms[index]) return -1;
    }

    var window: [MAX_FFT]f64 = undefined;
    for (0..fft_size) |index| {
        window[index] = 0.5 - 0.5 * @cos(2.0 * PI * @as(f64, @floatFromInt(index)) /
            @as(f64, @floatFromInt(fft_size)));
    }
    var logged: [MAX_MELS][MAX_FRAMES]f64 = undefined;
    for (0..frames) |frame| {
        var real: [MAX_FFT]f64 = @splat(0.0);
        var imag: [MAX_FFT]f64 = @splat(0.0);
        for (0..fft_size) |index| real[index] = padded[frame * hop + index] * window[index];
        fft(&real, &imag, fft_size);
        var power: [MAX_FFT / 2 + 1]f32 = undefined;
        for (0..bin_count) |index| {
            const real32: f32 = @floatCast(real[index]);
            const imag32: f32 = @floatCast(imag[index]);
            const squared: f32 = real32 * real32 + imag32 * imag32;
            const magnitude: f32 = @floatCast(@sqrt(@as(f64, squared)));
            power[index] = magnitude * magnitude;
        }
        for (0..mel_count) |filter_index| {
            const first = bins[filter_index];
            const middle = bins[filter_index + 1];
            const last = bins[filter_index + 2];
            const rise = middle - first;
            const fall = last - middle;
            var energy: f64 = 0.0;
            var index = first;
            while (index < middle) : (index += 1) {
                const weight = if (rise == 1) 0.0 else
                    @as(f64, @floatFromInt(index - first)) / @as(f64, @floatFromInt(rise - 1));
                energy += @as(f64, power[index]) * weight;
            }
            index = middle;
            while (index < last) : (index += 1) {
                const weight = if (fall == 1) 1.0 else
                    1.0 - @as(f64, @floatFromInt(index - middle)) / @as(f64, @floatFromInt(fall - 1));
                energy += @as(f64, power[index]) * weight;
            }
            energy *= norms[filter_index];
            if (energy <= 0.0 or energy != energy) return -1;
            logged[filter_index][frame] = 10.0 * @log10(energy);
        }
    }

    var result: [MAX_DCTS][MAX_FRAMES]f64 = undefined;
    for (0..dct_count) |coefficient| {
        const mel_float: f64 = @floatFromInt(mel_count);
        const scale = if (coefficient == 0) 1.0 / @sqrt(mel_float) else @sqrt(2.0 / mel_float);
        for (0..frames) |frame| {
            var total: f64 = 0.0;
            for (0..mel_count) |index| {
                const basis = if (coefficient == 0) scale else scale * @cos(
                    @as(f64, @floatFromInt(coefficient)) * (2.0 * @as(f64, @floatFromInt(index)) + 1.0) * PI /
                        (2.0 * mel_float),
                );
                total += basis * logged[index][frame];
            }
            if (total != total) return -1;
            result[coefficient][frame] = total;
        }
    }

    const required = dct_count * frames * 8;
    if (output == null or capacity < required) return -2;
    const output_ptr = output.?;
    for (0..dct_count) |coefficient| {
        for (0..frames) |frame| putF64Le(output_ptr, (coefficient * frames + frame) * 8, result[coefficient][frame]);
    }
    return @intCast(required);
}
