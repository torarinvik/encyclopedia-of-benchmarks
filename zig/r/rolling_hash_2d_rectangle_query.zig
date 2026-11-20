const std = @import("std");

const max_h: usize = 32;
const max_w: usize = 32;
const max_q: usize = 128;
const max_input: usize = 1540;
const max_output: usize = 1024;
const modulus: i64 = 1_000_000_007;
const row_base: i64 = 31;
const col_base: i64 = 37;

fn storeI64Le(output: *[max_output]u8, offset: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |byte| output[offset + byte] = @truncate(bits >> @intCast(8 * byte));
}

export fn rolling_hash_2d_rectangle_query(
    input: ?[*]const i64, length: usize, output: ?[*]u8, capacity: usize,
) i64 {
    if (input == null or length < 3 or length > max_input) return -1;
    const words = input.?;
    const h_value = words[0];
    const w_value = words[1];
    const q_value = words[2];
    if (h_value < 1 or h_value > @as(i64, @intCast(max_h)) or
        w_value < 1 or w_value > @as(i64, @intCast(max_w)) or
        q_value < 1 or q_value > @as(i64, @intCast(max_q))) return -1;
    const h: usize = @intCast(h_value);
    const w: usize = @intCast(w_value);
    const q: usize = @intCast(q_value);
    if (length != 3 + h * w + 4 * q) return -1;
    const query_offset = 3 + h * w;
    for (0..h * w) |i| if (words[3 + i] < 0 or words[3 + i] > 255) return -1;
    for (0..q) |i| {
        const r0 = words[query_offset + 4 * i];
        const c0 = words[query_offset + 4 * i + 1];
        const r1 = words[query_offset + 4 * i + 2];
        const c1 = words[query_offset + 4 * i + 3];
        if (r0 < 0 or r0 > r1 or r1 > h_value or c0 < 0 or c0 > c1 or c1 > w_value) return -1;
    }
    const required = 8 * q;
    if (output == null or capacity < required) return -2;

    var row_power = [_]i64{0} ** (max_h + 1);
    var col_power = [_]i64{0} ** (max_w + 1);
    row_power[0] = 1;
    col_power[0] = 1;
    for (1..h + 1) |i| row_power[i] = row_power[i - 1] * row_base % modulus;
    for (1..w + 1) |j| col_power[j] = col_power[j - 1] * col_base % modulus;
    var prefix = [_]i64{0} ** ((max_h + 1) * (max_w + 1));
    for (1..h + 1) |r| {
        var row_hash: i64 = 0;
        for (1..w + 1) |c| {
            row_hash = (row_hash * col_base + words[3 + (r - 1) * w + c - 1]) % modulus;
            prefix[r * (max_w + 1) + c] =
                (prefix[(r - 1) * (max_w + 1) + c] * row_base + row_hash) % modulus;
        }
    }
    var staged = [_]u8{0} ** max_output;
    for (0..q) |i| {
        const r0: usize = @intCast(words[query_offset + 4 * i]);
        const c0: usize = @intCast(words[query_offset + 4 * i + 1]);
        const r1: usize = @intCast(words[query_offset + 4 * i + 2]);
        const c1: usize = @intCast(words[query_offset + 4 * i + 3]);
        const rh = r1 - r0;
        const cw = c1 - c0;
        var value = prefix[r1 * (max_w + 1) + c1]
            - prefix[r0 * (max_w + 1) + c1] * row_power[rh] % modulus
            - prefix[r1 * (max_w + 1) + c0] * col_power[cw] % modulus
            + prefix[r0 * (max_w + 1) + c0] * row_power[rh] % modulus * col_power[cw] % modulus;
        value %= modulus;
        if (value < 0) value += modulus;
        storeI64Le(&staged, 8 * i, value);
    }
    const destination = output.?;
    for (0..required) |i| destination[i] = staged[i];
    return @intCast(required);
}
