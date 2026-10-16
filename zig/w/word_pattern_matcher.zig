fn matchAt(pattern: []const i64, text: []const i64, pi: usize, ti: usize, starts: *[95]i32, lengths: *[95]i32) bool {
    if (pi == pattern.len) return ti == text.len;
    const symbol: usize = @intCast(pattern[pi] - 32);
    if (lengths[symbol] >= 0) {
        const size: usize = @intCast(lengths[symbol]);
        if (ti + size > text.len) return false;
        for (0..size) |j| if (text[ti + j] != text[@as(usize, @intCast(starts[symbol])) + j]) { return false; };
        return matchAt(pattern, text, pi + 1, ti + size, starts, lengths);
    }
    var size: usize = 1;
    while (ti + size <= text.len) : (size += 1) {
        var used = false;
        for (0..95) |other| if (lengths[other] == size) {
            var same = true;
            for (0..size) |j| if (text[ti + j] != text[@as(usize, @intCast(starts[other])) + j]) { same = false; break; };
            if (same) { used = true; break; }
        };
        if (used) continue;
        starts[symbol] = @intCast(ti); lengths[symbol] = @intCast(size);
        if (matchAt(pattern, text, pi + 1, ti + size, starts, lengths)) return true;
        lengths[symbol] = -1;
    }
    return false;
}

export fn word_pattern_matcher(input: ?[*]const i64, length: usize, output: ?[*]u8, capacity: usize) i64 {
    _ = output; _ = capacity;
    if (input == null or length < 2) return -1;
    const values = input.?[0..length];
    if (values[0] < 0 or values[0] > 8) return -1;
    const plen: usize = @intCast(values[0]);
    if (length < plen + 2) return -1;
    const text_index = plen + 1;
    if (values[text_index] < 0 or values[text_index] > 32) return -1;
    const tlen: usize = @intCast(values[text_index]);
    if (length != text_index + 1 + tlen) return -1;
    for (values[1 .. plen + 1]) |ch| if (ch < 32 or ch > 126) return -1;
    for (values[text_index + 1 ..]) |ch| if (ch < 32 or ch > 126) return -1;
    var starts = @as([95]i32, @splat(-1));
    var lengths = @as([95]i32, @splat(-1));
    return if (matchAt(values[1 .. plen + 1], values[text_index + 1 ..], 0, 0, &starts, &lengths)) 1 else 0;
}
