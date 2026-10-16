const std = @import("std");
const invalid_result: f64 = -1.0e300;

fn coefficients(kind: i64, frequency: f64, samplerate: f64, gain_db: f64, q_factor: f64) [6]f64 {
    const w0 = 6.283185307179586476925286766559 * frequency / samplerate;
    const sine = @sin(w0);
    const cosine = @cos(w0);
    const alpha = sine / (2.0 * q_factor);
    var a0 = 1.0 + alpha;
    var a1 = -2.0 * cosine;
    var a2 = 1.0 - alpha;
    var b0: f64 = 0.0;
    var b1: f64 = 0.0;
    var b2: f64 = 0.0;
    if (kind == 0) {
        b0 = (1.0 - cosine) / 2.0; b1 = 1.0 - cosine; b2 = b0;
    } else if (kind == 1) {
        b0 = (1.0 + cosine) / 2.0; b1 = -1.0 - cosine; b2 = b0;
    } else if (kind == 2) {
        b0 = sine / 2.0; b1 = 0.0; b2 = -b0;
    } else if (kind == 3) {
        b0 = 1.0 - alpha; b1 = -2.0 * cosine; b2 = 1.0 + alpha;
        a0 = b2; a1 = b1; a2 = b0;
    } else if (kind == 4) {
        const big_a = std.math.pow(f64, 10.0, gain_db / 40.0);
        b0 = 1.0 + alpha * big_a; b1 = -2.0 * cosine; b2 = 1.0 - alpha * big_a;
        a0 = 1.0 + alpha / big_a; a1 = -2.0 * cosine; a2 = 1.0 - alpha / big_a;
    } else if (kind == 5 or kind == 6) {
        const big_a = std.math.pow(f64, 10.0, gain_db / 40.0);
        const pmc = (big_a + 1.0) - (big_a - 1.0) * cosine;
        const ppmc = (big_a + 1.0) + (big_a - 1.0) * cosine;
        const mpc = (big_a - 1.0) - (big_a + 1.0) * cosine;
        const pmpc = (big_a - 1.0) + (big_a + 1.0) * cosine;
        const aa2 = 2.0 * @sqrt(big_a) * alpha;
        if (kind == 5) {
            b0 = big_a * (pmc + aa2); b1 = 2.0 * big_a * mpc; b2 = big_a * (pmc - aa2);
            a0 = ppmc + aa2; a1 = -2.0 * pmpc; a2 = ppmc - aa2;
        } else {
            b0 = big_a * (ppmc + aa2); b1 = -2.0 * big_a * pmpc; b2 = big_a * (ppmc - aa2);
            a0 = pmc + aa2; a1 = 2.0 * mpc; a2 = pmc - aa2;
        }
    } else if (kind == 7) {
        b0 = 1.0; b1 = -2.0 * cosine; b2 = 1.0;
    } else {
        b0 = alpha; b1 = 0.0; b2 = -alpha;
    }
    return .{ a0, a1, a2, b0, b1, b2 };
}

export fn butterworth_filter(values: [*c]const i64, length: usize) f64 {
    if (values == null or length != 6) return invalid_result;
    const kind = values[0];
    const coefficient_index = values[1];
    const frequency = values[2];
    const samplerate = values[3];
    const gain_milli_db = values[4];
    const q_micro = values[5];
    if (kind < 0 or kind > 8 or coefficient_index < 0 or coefficient_index > 5 or
        frequency < 1 or frequency > 95999 or samplerate < 1 or samplerate > 192000 or
        2 * frequency >= samplerate) return invalid_result;
    if (q_micro != -1 and (q_micro < 1 or q_micro > 10000000)) return invalid_result;
    const needs_gain = kind >= 4 and kind <= 6;
    if (needs_gain) {
        if (gain_milli_db < -60000 or gain_milli_db > 60000) return invalid_result;
    } else if (gain_milli_db != 0) return invalid_result;
    const gain_db = if (needs_gain) @as(f64, @floatFromInt(gain_milli_db)) / 1000.0 else 0.0;
    const q_factor = if (q_micro == -1) 1.0 / @sqrt(@as(f64, 2.0))
                     else @as(f64, @floatFromInt(q_micro)) / 1000000.0;
    const output = coefficients(kind, @floatFromInt(frequency), @floatFromInt(samplerate), gain_db, q_factor);
    return output[@intCast(coefficient_index)];
}
