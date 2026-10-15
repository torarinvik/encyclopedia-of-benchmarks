const std = @import("std");

const MAX_INPUT_VALUES: usize = 66;
const MAX_DECODED_LENGTH: usize = 52;

fn decodeGroup(values: [*]const i64, start: usize, count: usize) ?u32 {
    var value: u64 = 0;
    for (0..5) |index| {
        var digit: u64 = 84;
        if (index < count) {
            const byte = values[start + index];
            if (byte < 33 or byte > 117) return null;
            digit = @intCast(byte - 33);
        }
        value = value * 85 + digit;
    }
    if (value > std.math.maxInt(u32)) return null;
    return @intCast(value);
}

export fn base85(values: [*]const i64, length: usize, output: [*]u8, output_capacity: usize) i64 {
    if (length == 0 or length > MAX_INPUT_VALUES) return -1;
    const mode = values[0];
    const payload_length = length - 1;
    var output_length: usize = 0;
    if (mode == 0) {
        for (1..length) |index| {
            const byte = values[index];
            if (byte < 0 or byte > 255) return -1;
        }
        const remainder = payload_length % 4;
        output_length = (payload_length / 4) * 5 + (if (remainder == 0) 0 else remainder + 1);
    } else if (mode == 1) {
        if (payload_length % 5 == 1) return -1;
        var offset: usize = 0;
        while (offset < payload_length) {
            const count = @min(payload_length - offset, 5);
            if (decodeGroup(values, offset + 1, count) == null) return -1;
            output_length += if (count == 5) 4 else count - 1;
            offset += count;
        }
        if (output_length > MAX_DECODED_LENGTH) return -1;
    } else {
        return -1;
    }
    if (output_capacity < output_length) return -2;

    var written: usize = 0;
    if (mode == 0) {
        const powers = [_]u64{ 52_200_625, 614_125, 7_225, 85, 1 };
        var offset: usize = 0;
        while (offset < payload_length) {
            const count = @min(payload_length - offset, 4);
            var value: u64 = 0;
            for (0..4) |byte| {
                value <<= 8;
                if (byte < count) value |= @intCast(values[offset + byte + 1]);
            }
            for (0..5) |digit| {
                const encoded: u8 = @intCast(value / powers[digit] + 33);
                value %= powers[digit];
                if (count == 4 or digit < count + 1) {
                    output[written] = encoded;
                    written += 1;
                }
            }
            offset += 4;
        }
    } else {
        var offset: usize = 0;
        while (offset < payload_length) {
            const count = @min(payload_length - offset, 5);
            const value: u64 = (decodeGroup(values, offset + 1, count) orelse return -1);
            const byte_count = if (count == 5) 4 else count - 1;
            for (0..byte_count) |byte| {
                output[written] = @intCast((value >> (24 - 8 * byte)) & 255);
                written += 1;
            }
            offset += count;
        }
    }
    return @intCast(written);
}
