fn radix_order_key(value: i64) u64 {
    const sign_bit = @as(u64, 1) << 63;
    if (value < 0) return sign_bit - 1 - @as(u64, @intCast(-(value + 1)));
    return sign_bit + @as(u64, @intCast(value));
}

/// Stable LSD radix sort for signed 64-bit values.
export fn radix_sort(values: [*]i64, scratch: [*]i64, length: usize) void {
    if (length < 2) return;
    for (0..8) |pass| {
        @memset(scratch[0..256], 0);
        const shift: u6 = @intCast(pass * 8);
        for (0..length) |index| {
            const bucket: usize = @intCast((radix_order_key(values[index]) >> shift) & 255);
            scratch[bucket] += 1;
        }
        var next: usize = 0;
        for (0..256) |bucket| {
            const count: usize = @intCast(scratch[bucket]);
            scratch[bucket] = @intCast(next);
            next += count;
        }
        for (0..length) |index| {
            const bucket: usize = @intCast((radix_order_key(values[index]) >> shift) & 255);
            const destination: usize = @intCast(scratch[bucket]);
            scratch[bucket] += 1;
            scratch[256 + destination] = values[index];
        }
        @memcpy(values[0..length], scratch[256 .. 256 + length]);
    }
}
