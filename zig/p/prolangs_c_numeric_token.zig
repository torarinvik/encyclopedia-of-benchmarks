const std = @import("std");

fn putI32(out: [*]u8, at: usize, value: i32) void {
    const bits: u32 = @bitCast(value);
    for (0..4) |b| out[at + b] = @truncate(bits >> @intCast(b * 8));
}

export fn prolangs_c_numeric_token(input: [*]const i64, length: usize,
    output: [*]u8, capacity: usize) i64 {
    if (length < 1 or length > 24) return -1;
    var text: [24]u8 = undefined;
    for (0..length) |j| { if (input[j] < 32 or input[j] > 127) return -1; text[j] = @intCast(input[j]); }
    var i: usize = 0;
    var integer: u32 = 0;
    var had_integer = false;
    if (text[i] >= 48 and text[i] <= 57) {
        had_integer = true;
        while (i < length and text[i] >= 48 and text[i] <= 57) {
            const d: u32 = text[i] - 48; i += 1;
            if (integer > (2147483647 - d) / 10) return -1;
            integer = integer * 10 + d;
        }
        if (i == length) {
            if (capacity < 12) return -2;
            putI32(output, 0, 256); putI32(output, 4, @intCast(integer)); putI32(output, 8, 0); return 12;
        }
    }
    var frac_digits: u32 = 0; var frac_count: usize = 0; var leading_zeros: usize = 0; var has_dot = false;
    if (i < length and text[i] == 46) {
        has_dot = true; i += 1;
        while (i < length and text[i] == 48) { leading_zeros += 1; i += 1; }
        if (leading_zeros > 6) return -1;
        while (i < length and text[i] >= 48 and text[i] <= 57) {
            if (frac_count == 6) return -1;
            frac_digits = frac_digits * 10 + (text[i] - 48); frac_count += 1; i += 1;
        }
        if (leading_zeros + frac_count > 6) return -1;
    }
    var value: f32 = 0;
    if (frac_count != 0) {
        value = @floatFromInt(frac_digits);
        while (value >= 1) value /= 10;
        while (leading_zeros > 0) { value /= 10; leading_zeros -= 1; }
    }
    value += @floatFromInt(integer);
    var has_exp = false;
    if (i < length and (text[i] == 101 or text[i] == 69)) {
        has_exp = true; i += 1; var sign: i32 = 1;
        if (i < length and (text[i] == 43 or text[i] == 45)) { if (text[i] == 45) sign = -1; i += 1; }
        if (i == length or text[i] < 48 or text[i] > 57) return -1;
        var exponent: i32 = 0;
        while (i < length and text[i] >= 48 and text[i] <= 57) { exponent = exponent * 10 + @as(i32, text[i] - 48); i += 1; if (exponent > 6) return -1; }
        exponent *= sign;
        while (exponent > 0) { value *= 10; exponent -= 1; }
        while (exponent < 0) { value /= 10; exponent += 1; }
    }
    if (i != length or (!has_dot and !has_exp) or (!had_integer and !has_dot)) return -1;
    if (capacity < 12) return -2;
    putI32(output, 0, 2001); putI32(output, 4, @intCast(integer)); putI32(output, 8, @bitCast(value));
    return 12;
}
