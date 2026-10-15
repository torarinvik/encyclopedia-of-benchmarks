/// Hash ASCII byte arrays with the pinned 64-bit SDBM recurrence.
const MAX_BYTES: usize = 64;

fn signedBits(value: u64) i64 {
    const high_bit: u64 = @as(u64, 1) << 63;
    if (value < high_bit) return @intCast(value);
    return std.math.minInt(i64) + @as(i64, @intCast(value - high_bit));
}

const std = @import("std");

export fn hash_sdbm(input: [*c]const i64, length: usize) i64 {
    if (length == 0 or length > MAX_BYTES or input == null) return -1;
    var hash: u64 = 0;
    for (0..length) |index| {
        const byte = input[index];
        if (byte < 1 or byte > 127) return -1;
        const value: u64 = @intCast(byte);
        hash = value +% (hash << 6) +% (hash << 16) -% hash;
    }
    return signedBits(hash);
}
