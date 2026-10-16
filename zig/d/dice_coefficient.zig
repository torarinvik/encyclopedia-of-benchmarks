const INVALID_RESULT: f64 = -1.0e300;
const MAX_STRING_LENGTH: usize = 128;
const ALPHABET_SIZE: usize = 95;

pub export fn dice_coefficient(values: [*c]const i64, length: usize) f64 {
    if (values == null or length < 2) return INVALID_RESULT;
    const len_a_raw = values[0];
    const len_b_raw = values[1];
    if (len_a_raw < 0 or len_a_raw > MAX_STRING_LENGTH or len_b_raw < 0 or len_b_raw > MAX_STRING_LENGTH) return INVALID_RESULT;
    const len_a: usize = @intCast(len_a_raw);
    const len_b: usize = @intCast(len_b_raw);
    if (length != 2 + len_a + len_b) return INVALID_RESULT;
    const chars = values[2..][0 .. len_a + len_b];
    for (chars) |code| if (code < 32 or code > 126) return INVALID_RESULT;
    const equal = len_a == len_b and std.mem.eql(i64, values[2 .. 2 + len_a], values[2 + len_a .. 2 + len_a + len_b]);
    if (equal) return 1.0;
    if (len_a < 2 or len_b < 2) return 0.0;
    var present: [ALPHABET_SIZE * ALPHABET_SIZE]bool = @splat(false);
    for (0..len_a - 1) |i| {
        const first: usize = @intCast(values[2 + i] - 32);
        const second: usize = @intCast(values[2 + i + 1] - 32);
        present[first * ALPHABET_SIZE + second] = true;
    }
    var common: usize = 0;
    for (0..len_b - 1) |i| {
        const first: usize = @intCast(values[2 + len_a + i] - 32);
        const second: usize = @intCast(values[2 + len_a + i + 1] - 32);
        if (present[first * ALPHABET_SIZE + second]) common += 1;
    }
    const denominator: f64 = @floatFromInt(len_a + len_b - 2);
    const score = (2.0 * @as(f64, @floatFromInt(common))) / denominator;
    return @floor(score * 100.0) / 100.0;
}

const std = @import("std");
