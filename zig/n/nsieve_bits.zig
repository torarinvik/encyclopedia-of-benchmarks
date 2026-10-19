const std = @import("std");

const MAX_LIMIT: i64 = 1_000_000;
const MAX_WORDS: usize = 15_626;

fn countPrimes(limit: i64) i64 {
    var bits: [MAX_WORDS]u64 = undefined;
    @memset(&bits, std.math.maxInt(u64));
    var count: i64 = 0;
    var value: i64 = 2;
    while (value <= limit) : (value += 1) {
        const word: usize = @intCast(value >> 6);
        const mask = @as(u64, 1) << @intCast(value & 63);
        if ((bits[word] & mask) != 0) {
            count += 1;
            var multiple = value + value;
            while (multiple <= limit) : (multiple += value) {
                const multiple_word: usize = @intCast(multiple >> 6);
                const multiple_mask = @as(u64, 1) << @intCast(multiple & 63);
                if ((bits[multiple_word] & multiple_mask) != 0) bits[multiple_word] ^= multiple_mask;
            }
        }
    }
    return count;
}

fn putU64Le(output: [*]u8, offset: usize, value: u64) void {
    for (0..8) |byte| output[offset + byte] = @truncate(value >> @intCast(byte * 8));
}

export fn benchmarkgame_nsieve_bits(input: [*c]const i64, length: usize, output: [*c]u8, capacity: usize) i64 {
    if (input == null or length != 1) return -1;
    const limit = input[0];
    if (limit < 0 or limit > MAX_LIMIT) return -1;
    if (output == null or capacity < 24) return -2;
    for (0..3) |pass| putU64Le(output, pass * 8, @intCast(countPrimes(limit >> @intCast(pass))));
    return 24;
}

