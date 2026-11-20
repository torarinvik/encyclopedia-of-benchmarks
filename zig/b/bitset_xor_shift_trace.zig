const max_bits: usize = 4096;
const max_words: usize = 64;
const max_operations: usize = 64;

fn popcount64(value: u64) i32 {
    var remaining = value;
    var count: i32 = 0;
    while (remaining != 0) {
        remaining &= remaining - 1;
        count += 1;
    }
    return count;
}

fn store_i32_le(output: [*]u8, offset: usize, value: i32) void {
    const bits: u32 = @bitCast(value);
    for (0..4) |byte| output[offset + byte] = @truncate(bits >> @intCast(8 * byte));
}

export fn bitset_xor_shift_trace(input_opt: ?[*]const i64, length: usize,
    output_opt: ?[*]u8, capacity: usize) i64 {
    if (input_opt == null or length < 3 or length > 131) return -1;
    const input = input_opt.?;
    const n64 = input[0];
    const q64 = input[1];
    if (n64 < 1 or n64 > @as(i64, max_bits) or q64 < 0 or q64 > @as(i64, max_operations)) return -1;
    const n: usize = @intCast(n64);
    const q: usize = @intCast(q64);
    const word_count = (n + 63) / 64;
    const shift_offset = 2 + word_count;
    if (length != shift_offset + q) return -1;

    var words: [max_words]u64 = @splat(0);
    for (0..word_count) |word| words[word] = @bitCast(input[2 + word]);
    const tail_bits = n % 64;
    const tail_mask: u64 = if (tail_bits == 0) ~@as(u64, 0) else (@as(u64, 1) << @intCast(tail_bits)) - 1;
    if ((words[word_count - 1] & ~tail_mask) != 0) return -1;
    for (0..q) |operation| {
        const shift = input[shift_offset + operation];
        if (shift < -(n64 - 1) or shift > n64 - 1) return -1;
    }

    const output_bytes = q * 4;
    if (output_bytes != 0 and (output_opt == null or capacity < output_bytes)) return -2;
    const output = if (output_opt) |pointer| pointer else undefined;
    var counts: [max_operations]i32 = @splat(0);
    for (0..q) |operation| {
        const shift = input[shift_offset + operation];
        if (shift == 0) {
            for (0..word_count) |word| words[word] = 0;
        } else if (shift > 0) {
            const distance: usize = @intCast(shift);
            const whole = distance / 64;
            const part = distance % 64;
            for (0..word_count) |destination| {
                const source = destination + whole;
                var shifted: u64 = if (source < word_count) words[source] >> @intCast(part) else 0;
                if (part != 0 and source + 1 < word_count)
                    shifted |= words[source + 1] << @intCast(64 - part);
                words[destination] ^= shifted;
            }
        } else {
            const distance: usize = @intCast(-shift);
            const whole = distance / 64;
            const part = distance % 64;
            var destination = word_count;
            while (destination > 0) {
                destination -= 1;
                const source: isize = @as(isize, @intCast(destination)) - @as(isize, @intCast(whole));
                var shifted: u64 = if (source >= 0) words[@intCast(source)] << @intCast(part) else 0;
                if (part != 0 and source > 0)
                    shifted |= words[@intCast(source - 1)] >> @intCast(64 - part);
                words[destination] ^= shifted;
            }
        }
        words[word_count - 1] &= tail_mask;
        var count: i32 = 0;
        for (0..word_count) |word| count += popcount64(words[word]);
        counts[operation] = count;
    }
    if (output_bytes != 0) {
        for (0..q) |operation| store_i32_le(output, operation * 4, counts[operation]);
    }
    return @intCast(output_bytes);
}
