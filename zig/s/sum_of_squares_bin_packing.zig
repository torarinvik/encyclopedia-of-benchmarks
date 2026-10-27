fn putI64(output: [*c]u8, word: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |byte| output[word * 8 + byte] = @truncate(bits >> @intCast(8 * byte));
}

export fn sum_of_squares_bin_packing(input_opt: ?[*]const i64, length: usize,
    output_opt: ?[*]u8, capacity: usize) i64 {
    const input = input_opt orelse return -1;
    if (length < 2 or length > 66) return -1;
    const capacity0 = input[0]; const n0 = input[1];
    if (capacity0 < 1 or capacity0 > 64 or n0 < 0 or n0 > 64 or length != 2 + @as(usize, @intCast(n0))) return -1;
    const n: usize = @intCast(n0);
    for (0..n) |i| if (input[i + 2] < 1 or input[i + 2] > capacity0) return -1;
    var histogram = [_]i64{0} ** 65;
    var loads = [_]i64{0} ** 64;
    var assignments = [_]i64{0} ** 64;
    var bins: usize = 0;
    var score: i64 = 0;
    for (0..n) |item| {
        const size = input[item + 2];
        var selected = bins;
        var best_score: i64 = 9223372036854775807;
        for (0..bins) |bin| {
            const from = loads[bin]; const to = from + size;
            if (to > capacity0) continue;
            var candidate = score;
            if (from < capacity0) { const h = histogram[@intCast(from)]; candidate += (h - 1) * (h - 1) - h * h; }
            if (to < capacity0) { const h = histogram[@intCast(to)]; candidate += (h + 1) * (h + 1) - h * h; }
            if (candidate < best_score) { best_score = candidate; selected = bin; }
        }
        var new_score = score;
        if (size < capacity0) { const h = histogram[@intCast(size)]; new_score += (h + 1) * (h + 1) - h * h; }
        if (new_score < best_score) { best_score = new_score; selected = bins; }
        if (selected == bins) {
            loads[bins] = size; assignments[item] = @intCast(bins);
            if (size < capacity0) histogram[@intCast(size)] += 1;
            bins += 1;
        } else {
            const from = loads[selected]; const to = from + size;
            if (from < capacity0) histogram[@intCast(from)] -= 1;
            if (to < capacity0) histogram[@intCast(to)] += 1;
            loads[selected] = to; assignments[item] = @intCast(selected);
        }
        score = best_score;
    }
    const bytes = 8 * (n + 1);
    const output = output_opt orelse return -2;
    if (capacity < bytes) return -2;
    putI64(output, 0, @intCast(bins));
    for (0..n) |i| putI64(output, i + 1, assignments[i]);
    return @intCast(bytes);
}
