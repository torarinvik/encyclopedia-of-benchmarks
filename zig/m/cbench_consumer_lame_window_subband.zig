/*
 * Copyright (c) 1999 Takehiro TOMINAGA
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Library General Public
 * License as published by the Free Software Foundation; either
 * version 2 of the License, or (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
 * Library General Public License for more details.
 *
 * You should have received a copy of the GNU Library General Public
 * License along with this library; if not, write to the
 * Free Software Foundation, Inc., 59 Temple Place - Suite 330,
 * Boston, MA 02111-1307, USA.
 */
const PI: f64 = 3.14159265358979323846264338327950288;
const SAMPLE_COUNT: usize = 511;
const WINDOW_COUNT: usize = 256;
const INPUT_COUNT: usize = 767;
const MAX_INPUT_LENGTH: usize = 768;
const OUTPUT_BYTES: usize = 256;
const S_OFFSETS = [_]i64{334,398,462,14,78,142,206,16,80,144,208,272,336,400,464};
const T_OFFSETS = [_]i64{176,112,48,496,432,368,304,494,430,366,302,238,174,110,46};

fn storeI64Le(output: [*]u8, offset: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |byte| output[offset + byte] = @truncate(bits >> @intCast(8 * byte));
}
fn roundQ1000(value: f64) i64 {
    const scaled = value * 1000.0;
    const magnitude = if (scaled < 0.0) -scaled else scaled;
    const rounded: i64 = @intFromFloat(magnitude + 0.5);
    return if (scaled < 0.0) -rounded else rounded;
}
fn valid(values: []const i64) bool {
    if (values.len != INPUT_COUNT) return false;
    for (values[0..SAMPLE_COUNT]) |value| if (value < -32768 or value > 32767) return false;
    for (values[SAMPLE_COUNT..]) |value| if (value < -4500000 or value > 36000000) return false;
    if (values[SAMPLE_COUNT] <= 25000000) return false;
    for (8..WINDOW_COUNT) |index| {
        if ((index - 8) % 16 == 0 and values[SAMPLE_COUNT + index] <= 25000000) return false;
    }
    return true;
}
fn filterbank(input: []const i64, window: *[WINDOW_COUNT]f64) [32]f64 {
    const maximum = window[248];
    var mmax = [_]f64{0.0} ** 31;
    var mm = [_][31]f64{[_]f64{0.0} ** 31} ** 16;
    var wp: usize = 0; var wr: usize = 0;
    var w = window[wp]; wp += 1;
    mmax[15] = w / maximum;
    for (0..7) |_| { window[wr] = window[wp] / w; wr += 1; wp += 1; }
    var i: i64 = 14;
    while (i >= 0) : (i -= 1) {
        w = window[wp]; wp += 1;
        mmax[@intCast(i)] = w / maximum;
        mmax[@intCast(30 - i)] = w / maximum;
        for (0..15) |_| { window[wr] = window[wp] / w; wr += 1; wp += 1; }
    }
    wp += 1;
    for (0..7) |_| { window[wr] = window[wp] / maximum; wr += 1; wp += 1; }
    i = 15;
    while (i >= 0) : (i -= 1) {
        var k: i64 = 1;
        while (k < 32) : (k += 1) {
            const row: usize = @intCast(i); const col: usize = @intCast(k - 1);
            mm[row][col] = @cos(@as(f64, @floatFromInt((2 * i + 1) * k)) * PI / 64.0) * mmax[col];
        }
    }
    var inner = [_]f64{0.0} ** 31;
    var coeff: usize = 0;
    var t = @as(f64, @floatFromInt(input[255]));
    t += @as(f64, @floatFromInt(input[223] - input[287])) * window[coeff]; coeff += 1;
    t += @as(f64, @floatFromInt(input[191] + input[319])) * window[coeff]; coeff += 1;
    t += @as(f64, @floatFromInt(input[159] - input[351])) * window[coeff]; coeff += 1;
    t += @as(f64, @floatFromInt(input[127] + input[383])) * window[coeff]; coeff += 1;
    t += @as(f64, @floatFromInt(input[95] - input[415])) * window[coeff]; coeff += 1;
    t += @as(f64, @floatFromInt(input[63] + input[447])) * window[coeff]; coeff += 1;
    t += @as(f64, @floatFromInt(input[31] - input[479])) * window[coeff]; coeff += 1;
    inner[15] = t;
    i = 14;
    while (i >= 0) : (i -= 1) {
        var s = @as(f64, @floatFromInt(input[@intCast(270 - i)]));
        t = @as(f64, @floatFromInt(input[@intCast(240 + i)]));
        for (0..15) |ku| {
            const k: i64 = @intCast(ku);
            w = window[coeff]; coeff += 1;
            const si: usize = @intCast(S_OFFSETS[ku] + (if (k < 7) -i else i));
            const ti: usize = @intCast(T_OFFSETS[ku] + (if (k < 7) i else -i));
            const sv = @as(f64, @floatFromInt(input[si])) * w;
            const tv = @as(f64, @floatFromInt(input[ti])) * w;
            if (k >= 11) { s -= sv; } else { s += sv; }
            if (k >= 7 and k < 11) { t -= tv; } else { t += tv; }
        }
        inner[@intCast(30 - i)] = s;
        inner[@intCast(i)] = t;
    }
    var s = @as(f64, @floatFromInt(input[239]));
    s += @as(f64, @floatFromInt(input[175])) * window[coeff]; coeff += 1;
    s += @as(f64, @floatFromInt(input[111])) * window[coeff]; coeff += 1;
    s += @as(f64, @floatFromInt(input[47])) * window[coeff]; coeff += 1;
    s -= @as(f64, @floatFromInt(input[303])) * window[coeff]; coeff += 1;
    s -= @as(f64, @floatFromInt(input[367])) * window[coeff]; coeff += 1;
    s -= @as(f64, @floatFromInt(input[431])) * window[coeff]; coeff += 1;
    s -= @as(f64, @floatFromInt(input[495])) * window[coeff];
    var bands = [_]f64{0.0} ** 32;
    i = 15;
    while (i >= 0) : (i -= 1) {
        const row: usize = @intCast(i);
        var s0 = s; var s1 = t * mm[row][0]; var at: usize = 1;
        for (0..15) |_| { s0 += mm[row][at] * inner[at]; at += 1; s1 += mm[row][at] * inner[at]; at += 1; }
        bands[row] = s0 + s1; bands[@intCast(31 - i)] = s0 - s1;
    }
    return bands;
}

export fn cbench_consumer_lame_window_subband(
    input: ?[*]const i64, input_length: usize, output: ?[*]u8, output_capacity: usize,
) i64 {
    if (input == null or input_length == 0 or input_length > MAX_INPUT_LENGTH) return -1;
    const values = input.?[0..input_length];
    if (!valid(values)) return -1;
    var window: [WINDOW_COUNT]f64 = undefined;
    for (0..WINDOW_COUNT) |i| window[i] = @as(f64, @floatFromInt(values[SAMPLE_COUNT + i])) / 1000000000.0;
    const bands = filterbank(values, &window);
    var staged: [32]i64 = undefined;
    for (0..32) |i| staged[i] = roundQ1000(bands[i]);
    const out = output orelse return -2;
    if (output_capacity < OUTPUT_BYTES) return -2;
    for (0..32) |i| storeI64Le(out, 8 * i, staged[i]);
    return OUTPUT_BYTES;
}
