/// Compare Kernighan, modulo-shift, and byte-lookup set-bit counters.
export fn count_number_of_one_bits(number: i64, method: i64) i64 {
    if (number < 0 or number > 4_294_967_295 or method < 0 or method > 2) return -1;
    var remaining: u32 = @intCast(number);
    var count: i64 = 0;
    if (method == 0) {
        while (remaining != 0) {
            remaining &= remaining - 1;
            count += 1;
        }
        return count;
    }
    if (method == 1) {
        while (remaining != 0) {
            if (remaining % 2 == 1) count += 1;
            remaining >>= 1;
        }
        return count;
    }
    var lookup: [256]i64 = @splat(0);
    for (1..256) |index| lookup[index] = lookup[index >> 1] + @as(i64, @intCast(index & 1));
    return lookup[@as(usize, @intCast(remaining & 0xff))]
        + lookup[@as(usize, @intCast((remaining >> 8) & 0xff))]
        + lookup[@as(usize, @intCast((remaining >> 16) & 0xff))]
        + lookup[@as(usize, @intCast(remaining >> 24))];
}
