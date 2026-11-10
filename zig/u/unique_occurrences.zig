export fn unique_occurrences(values: [*c]const i64, length: usize) i64 {
    if (length == 0) return 1;
    if (length > 1000 or values == null) return -1;
    const first: u64 = @bitCast(values[0]);
    if (length == 1) return if (first +% 1000 <= 2000) 1 else -1;
    var largest_biased: u64 = 0;
    var different_bits: u64 = 0;
    for (0..length) |index| {
        const value: u64 = @bitCast(values[index]);
        different_bits |= value ^ first;
        largest_biased = @max(largest_biased, value +% 1000);
    }
    if (largest_biased > 2000) return -1;
    if (different_bits == 0) return 1;

    var counts: [2001]u16 = @splat(0);
    var touched: [44]u16 = @splat(0);
    var distinct: usize = 0;
    for (0..length) |index| {
        const slot: usize = @intCast(values[index] + 1000);
        if (counts[slot] == 0) {
            const next_distinct = distinct + 1;
            if (next_distinct * (next_distinct + 1) > 2 * length) return 0;
            touched[distinct] = @intCast(slot);
            distinct = next_distinct;
        }
        counts[slot] += 1;
    }
    var seen: [16]u64 = @splat(0);
    for (touched[0..distinct]) |slot| {
        const frequency: usize = counts[slot];
        const word = frequency >> 6;
        const bit = @as(u64, 1) << @as(u6, @truncate(frequency));
        if (seen[word] & bit != 0) return 0;
        seen[word] |= bit;
    }
    return 1;
}
