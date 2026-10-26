const MAX_SYMBOLS: usize = 20;
const MAX_CLEN: usize = 32;

// Clean-room IJG JPEG 6a table-generation profile; see package LICENSE.txt.
export fn mediabench_jpeg_optimal_huffman_table(
    input: ?[*]const i64, length: usize, output: ?[*]u8, capacity: usize,
) i64 {
    if (input == null or length < 3 or length > 41) return -1;
    const values = input.?;
    if (values[0] < 1 or values[0] > MAX_SYMBOLS) return -1;
    const count: usize = @intCast(values[0]);
    if (length != 1 + 2 * count) return -1;
    for (0..count) |i| {
        const symbol = values[1 + 2 * i];
        const frequency = values[2 + 2 * i];
        if (symbol < 0 or symbol > 255 or frequency < 1 or frequency > 1_000_000) return -1;
        for (0..i) |j| if (values[1 + 2 * j] == symbol) return -1;
    }
    const output_size = 17 + count;
    if (output == null or capacity < output_size) return -2;

    var freq = [_]i64{0} ** 257;
    var code_size = [_]i32{0} ** 257;
    var others = [_]i32{-1} ** 257;
    var bits = [_]i32{0} ** (MAX_CLEN + 1);
    for (0..count) |i| freq[@intCast(values[1 + 2 * i])] = values[2 + 2 * i];
    freq[256] = 1;
    while (true) {
        var c1: i32 = -1;
        var c2: i32 = -1;
        var value: i64 = 1_000_000_000;
        for (0..257) |i| {
            if (freq[i] != 0 and freq[i] <= value) { value = freq[i]; c1 = @intCast(i); }
        }
        value = 1_000_000_000;
        for (0..257) |i| {
            if (freq[i] != 0 and freq[i] <= value and @as(i32, @intCast(i)) != c1) { value = freq[i]; c2 = @intCast(i); }
        }
        if (c2 < 0) break;
        const u1: usize = @intCast(c1);
        const u2: usize = @intCast(c2);
        freq[u1] += freq[u2]; freq[u2] = 0;
        code_size[u1] += 1;
        var branch = c1;
        while (others[@intCast(branch)] >= 0) { branch = others[@intCast(branch)]; code_size[@intCast(branch)] += 1; }
        others[@intCast(branch)] = c2;
        code_size[u2] += 1;
        branch = c2;
        while (others[@intCast(branch)] >= 0) { branch = others[@intCast(branch)]; code_size[@intCast(branch)] += 1; }
    }
    for (0..257) |i| {
        if (code_size[i] != 0) { if (code_size[i] > @as(i32, MAX_CLEN)) return -1; bits[@intCast(code_size[i])] += 1; }
    }
    var i: usize = MAX_CLEN;
    while (i > 16) : (i -= 1) {
        while (bits[i] > 0) {
            var j: i32 = @intCast(i) - 2;
            while (j >= 0 and bits[@intCast(j)] == 0) : (j -= 1) {}
            if (j < 0 or bits[i] < 2) return -1;
            bits[i] -= 2; bits[i - 1] += 1; bits[@intCast(j + 1)] += 2; bits[@intCast(j)] -= 1;
        }
    }
    var longest: usize = 16;
    while (longest > 0 and bits[longest] == 0) : (longest -= 1) {}
    if (longest == 0) return -1;
    bits[longest] -= 1;
    var symbol_count: usize = 0;
    for (1..MAX_CLEN + 1) |size| for (0..256) |symbol| {
        if (code_size[symbol] == @as(i32, @intCast(size))) symbol_count += 1;
    };
    if (symbol_count != count) return -1;
    const out = output.?;
    out[0] = @intCast(count);
    for (1..17) |slot| out[slot] = @intCast(bits[slot]);
    var used: usize = 17;
    for (1..MAX_CLEN + 1) |size| for (0..256) |symbol| {
        if (code_size[symbol] == @as(i32, @intCast(size))) { out[used] = @intCast(symbol); used += 1; }
    };
    return @intCast(used);
}
