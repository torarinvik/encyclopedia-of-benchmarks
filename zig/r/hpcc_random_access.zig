const MAX_TABLE_SIZE: usize = 256;
const DIGEST_MASK: u64 = 0x7fff_ffff_ffff_ffff;

export fn hpcc_random_access(input: ?[*]const i64, length: usize) i64 {
    if (input == null or length != 1) return -1;
    const size_value = input.?[0];
    if (size_value < 2 or size_value > MAX_TABLE_SIZE) return -1;
    if ((size_value & (size_value - 1)) != 0) return -1;

    const size: usize = @intCast(size_value);
    var table = [_]u64{0} ** MAX_TABLE_SIZE;
    for (0..size) |index| table[index] = @intCast(index);

    var ran: u64 = 1;
    for (0..4 * size) |_| {
        const feedback: u64 = if ((ran >> 63) != 0) 7 else 0;
        ran = (ran << 1) ^ feedback;
        table[@intCast(ran & @as(u64, @intCast(size - 1)))] ^= ran;
    }

    var digest: u64 = 0;
    for (0..size) |index| {
        const weight: u64 = @intCast(index + 1);
        digest +%= weight *% table[index];
    }
    return @intCast(digest & DIGEST_MASK);
}
