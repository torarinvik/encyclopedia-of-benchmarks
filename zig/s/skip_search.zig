const MAX_TEXT: usize = 4096;
const MAX_PATTERN: usize = 128;
const MAX_INPUT: usize = 4227;

export fn skip_search(input_opt: ?[*]const i64, length: usize) i64 {
    if (input_opt == null or length < 2 or length > MAX_INPUT) return -1;
    const input = input_opt.?;
    if (input[0] < 0 or input[0] > MAX_TEXT or input[1] < 1 or input[1] > MAX_PATTERN) return -1;
    const n: usize = @intCast(input[0]);
    const m: usize = @intCast(input[1]);
    if (length != 2 + n + m) return -1;

    var text = [_]u8{0} ** MAX_TEXT;
    var pattern = [_]u8{0} ** MAX_PATTERN;
    for (0..n) |q| {
        const value = input[2 + q];
        if (value < 0 or value > 3) return -1;
        text[q] = @intCast(value);
    }
    var positions = [_]usize{0} ** (4 * MAX_PATTERN);
    var bucket_size = [_]usize{0} ** 4;
    for (0..m) |q| {
        const value = input[2 + n + q];
        if (value < 0 or value > 3) return -1;
        const symbol: usize = @intCast(value);
        pattern[q] = @intCast(value);
        positions[symbol * MAX_PATTERN + bucket_size[symbol]] = q;
        bucket_size[symbol] += 1;
    }

    var count: i64 = 0;
    var offset_sum: i64 = 0;
    var offset_xor: i64 = 0;
    var sample = m - 1;
    while (sample < n) : (sample += m) {
        const symbol: usize = text[sample];
        for (0..bucket_size[symbol]) |item| {
            const pattern_position = positions[symbol * MAX_PATTERN + item];
            if (sample < pattern_position) continue;
            const start = sample - pattern_position;
            if (start > n - m) continue;
            var matched: usize = 0;
            while (matched < m and text[start + matched] == pattern[matched]) : (matched += 1) {}
            if (matched == m) {
                count += 1;
                offset_sum += @intCast(start);
                offset_xor ^= @intCast(start);
            }
        }
    }
    return (count << 36) | (offset_sum << 12) | offset_xor;
}
