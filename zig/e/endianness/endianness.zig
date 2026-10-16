/// Dispatch the seven pinned Python endianness helpers.
fn signedU64(bits: u64) i64 {
    if (bits <= std.math.maxInt(i64)) return @intCast(bits);
    return -1 - @as(i64, @intCast(std.math.maxInt(u64) - bits));
}

fn swapBytes(bits_input: u64, count: usize) u64 {
    var bits = bits_input;
    var reversed: u64 = 0;
    for (0..count) |_| {
        reversed = (reversed << 8) | (bits & 0xff);
        bits >>= 8;
    }
    return reversed;
}

const std = @import("std");

export fn endianness(input: [*c]const i64, length: usize) i64 {
    if (input == null or length == 0) return -1;
    const operation = input[0];
    if (operation >= 0 and operation <= 2) {
        if (length != 2) return -1;
        const value = input[1];
        if (operation == 0) {
            if (value < 0 or value > 65535) return -1;
            return @intCast(swapBytes(@intCast(value), 2));
        }
        if (operation == 1) {
            if (value < 0 or @as(u64, @intCast(value)) > 0xffffffff) return -1;
            return @intCast(swapBytes(@intCast(value), 4));
        }
        return signedU64(swapBytes(@bitCast(value), 8));
    }
    if (operation == 3 or operation == 4) {
        if (length < 3 or input[1] < 1 or input[1] > 8 or length != @as(usize, @intCast(input[1])) + 2) return -1;
        const count: usize = @intCast(input[1]);
        var result: u64 = 0;
        for (0..count) |index| {
            const byte = input[index + 2];
            if (byte < 0 or byte > 255) return -1;
            const shift = if (operation == 3) 8 * index else 8 * (count - 1 - index);
            result |= @as(u64, @intCast(byte)) << @intCast(shift);
        }
        return signedU64(result);
    }
    if (operation == 5 or operation == 6) {
        if (length != 3 or input[2] < 1 or input[2] > 8) return -1;
        const count: usize = @intCast(input[2]);
        const value: u64 = @bitCast(input[1]);
        if (count < 8 and (input[1] < 0 or (value >> @intCast(8 * count)) != 0)) return -1;
        return signedU64(if (operation == 5) value else swapBytes(value, count));
    }
    return -1;
}
