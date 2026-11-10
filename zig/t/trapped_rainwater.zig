fn trappedWaterWithSuffix(heights: []const i64, suffix: []u32) i64 {
    var boundary: u32 = 0;
    var index = heights.len;
    while (index > 0) {
        index -= 1;
        const raw: u64 = @bitCast(heights[index]);
        if (raw > 1_000_000) return -1;
        boundary = @max(boundary, @as(u32, @intCast(raw)));
        suffix[index] = boundary;
    }

    var water: u32 = 0;
    boundary = 0;
    for (heights, suffix[0..heights.len]) |raw, right_max| {
        const height: u32 = @intCast(raw);
        boundary = @max(boundary, height);
        water += @min(boundary, right_max) - height;
    }
    return water;
}

/// Sum trapped water using stored suffix maxima and a running prefix maximum.
export fn trapped_rainwater(heights: [*]const i64, length: usize) i64 {
    if (length > 4096) return -1;
    if (length <= 16) {
        var suffix: [16]u32 = undefined;
        return trappedWaterWithSuffix(heights[0..length], &suffix);
    }
    var suffix: [4096]u32 = undefined;
    return trappedWaterWithSuffix(heights[0..length], &suffix);
}
