fn bucket_order_key(value: i64) u64 {
    const sign_bit = @as(u64, 1) << 63;
    if (value < 0) return sign_bit - 1 - @as(u64, @intCast(-(value + 1)));
    return sign_bit + @as(u64, @intCast(value));
}

fn bucket_sort_insertion(values: [*]i64, base: usize, low: usize, high: usize) void {
    var index = low;
    if (low < high) index += 1;
    while (index < high) : (index += 1) {
        const key = values[base + index];
        var position = index;
        while (position > low and values[base + position - 1] > key) : (position -= 1) {
            values[base + position] = values[base + position - 1];
        }
        values[base + position] = key;
    }
}

/// Stable top-byte bucket sort for signed 64-bit values.
export fn bucket_sort(values: [*]i64, scratch: [*]i64, length: usize) void {
    if (length < 2) return;
    @memset(scratch[0..256], 0);
    for (0..length) |index| {
        const bucket: usize = @intCast(bucket_order_key(values[index]) >> 56);
        scratch[bucket] += 1;
    }
    var next: usize = 0;
    for (0..256) |bucket| {
        const count: usize = @intCast(scratch[bucket]);
        scratch[bucket] = @intCast(next);
        next += count;
    }
    for (0..length) |index| {
        const bucket: usize = @intCast(bucket_order_key(values[index]) >> 56);
        const destination: usize = @intCast(scratch[bucket]);
        scratch[bucket] += 1;
        scratch[256 + destination] = values[index];
    }
    var low: usize = 0;
    for (0..256) |bucket| {
        const high: usize = @intCast(scratch[bucket]);
        bucket_sort_insertion(scratch, 256, low, high);
        low = high;
    }
    for (0..length) |index| values[index] = scratch[256 + index];
}
