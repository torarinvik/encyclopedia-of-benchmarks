fn bitCount(value_input: usize) usize {
    var value = value_input;
    var count: usize = 0;
    while (value != 0) {
        count += value & 1;
        value >>= 1;
    }
    return count;
}

export fn problem345(input: [*c]const i64, length: usize) i64 {
    if (input == null or length < 2 or length > 226) return -1;
    const dimension = input[0];
    if (dimension < 1 or dimension > 15 or length != @as(usize, @intCast(dimension * dimension)) + 1) return -1;
    for (1..length) |index| {
        if (input[index] < 0 or input[index] > 1000) return -1;
    }

    var best = [_]i64{-1} ** 32768;
    best[0] = 0;
    const state_count: usize = @as(usize, 1) << @as(u5, @intCast(dimension));
    for (0..state_count) |mask| {
        if (best[mask] < 0) continue;
        const row = bitCount(mask);
        if (row >= @as(usize, @intCast(dimension))) continue;
        for (0..@as(usize, @intCast(dimension))) |column| {
            const bit = @as(usize, 1) << @as(u4, @intCast(column));
            if (mask & bit != 0) continue;
            const next = mask | bit;
            const input_index = 1 + row * @as(usize, @intCast(dimension)) + column;
            const candidate = best[mask] + input[input_index];
            if (candidate > best[next]) best[next] = candidate;
        }
    }
    return best[state_count - 1];
}
