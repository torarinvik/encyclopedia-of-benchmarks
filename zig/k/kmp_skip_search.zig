const MAX_TEXT: usize = 4096;
const MAX_PATTERN: usize = 128;
const MAX_INPUT_LENGTH: usize = 4227;

fn advance_sample(text: []const u8, n: usize, m: usize,
    last: [4]i32, sample: *isize) ?usize {
    while (true) {
        sample.* += @intCast(m);
        if (sample.* >= @as(isize, @intCast(n))) return null;
        const symbol = text[@intCast(sample.*)];
        const position = last[symbol];
        if (position >= 0) return @intCast(position);
    }
}

fn execute(input: []const i64) ?i64 {
    if (input.len < 2 or input.len > MAX_INPUT_LENGTH) return null;
    const n64 = input[0];
    const m64 = input[1];
    if (n64 < 0 or n64 > MAX_TEXT or m64 < 1 or m64 > MAX_PATTERN) return null;
    const n: usize = @intCast(n64);
    const m: usize = @intCast(m64);
    if (input.len != 2 + n + m) return null;

    var text: [MAX_TEXT]u8 = @splat(0);
    var pattern: [MAX_PATTERN]u8 = @splat(0);
    for (0..n) |q| {
        const symbol = input[2 + q];
        if (symbol < 0 or symbol > 3) return null;
        text[q] = @intCast(symbol);
    }
    for (0..m) |q| {
        const symbol = input[2 + n + q];
        if (symbol < 0 or symbol > 3) return null;
        pattern[q] = @intCast(symbol);
    }
    if (n < m) return 0;

    var mp_next: [MAX_PATTERN + 1]i32 = @splat(0);
    var kmp_next: [MAX_PATTERN + 1]i32 = @splat(0);
    var q: usize = 0;
    var border: i32 = -1;
    mp_next[0] = -1;
    while (q < m) {
        while (border >= 0 and pattern[q] != pattern[@intCast(border)])
            border = mp_next[@intCast(border)];
        q += 1;
        border += 1;
        mp_next[q] = border;
    }
    q = 0;
    border = -1;
    kmp_next[0] = -1;
    while (q < m) {
        while (border >= 0 and pattern[q] != pattern[@intCast(border)])
            border = kmp_next[@intCast(border)];
        q += 1;
        border += 1;
        if (q < m and pattern[q] == pattern[@intCast(border)])
            kmp_next[q] = kmp_next[@intCast(border)]
        else
            kmp_next[q] = border;
    }

    var last: [4]i32 = @splat(-1);
    var previous: [MAX_PATTERN]i32 = @splat(-1);
    for (0..m) |position| {
        const symbol: usize = @intCast(pattern[position]);
        previous[position] = last[symbol];
        last[symbol] = @intCast(position);
    }

    var sample: isize = -1;
    var i: i32 = @intCast(advance_sample(text[0..n], n, m, last, &sample) orelse return 0);
    var start = sample - @as(isize, @intCast(i));
    var wall: isize = 0;
    const period = @as(i32, @intCast(m)) - kmp_next[m];
    var count: i64 = 0;
    var offset_sum: i64 = 0;
    var offset_xor: i64 = 0;
    while (start <= @as(isize, @intCast(n - m))) {
        if (start > wall) wall = start;
        var k: i32 = @intCast(wall - start);
        while (k < @as(i32, @intCast(m)) and
            pattern[@intCast(k)] == text[@intCast(start + @as(isize, @intCast(k)))]) k += 1;
        wall = start + @as(isize, @intCast(k));
        if (k == @as(i32, @intCast(m))) {
            count += 1;
            offset_sum += @intCast(start);
            offset_xor ^= @intCast(start);
            i -= period;
        } else {
            i = previous[@intCast(i)];
        }
        if (i < 0) {
            i = @intCast(advance_sample(text[0..n], n, m, last, &sample) orelse break);
        }

        var kmp_start = start + @as(isize, @intCast(k)) - @as(isize, @intCast(kmp_next[@intCast(k)]));
        k = kmp_next[@intCast(k)];
        start = sample - @as(isize, @intCast(i));
        while (start < kmp_start or (kmp_start < start and start < wall)) {
            if (start < kmp_start) {
                i = previous[@intCast(i)];
                if (i < 0) {
                    i = @intCast(advance_sample(text[0..n], n, m, last, &sample) orelse
                        return (count << 36) | (offset_sum << 12) | offset_xor);
                }
                start = sample - @as(isize, @intCast(i));
            } else {
                kmp_start += k - mp_next[@intCast(k)];
                k = mp_next[@intCast(k)];
            }
        }
    }
    return (count << 36) | (offset_sum << 12) | offset_xor;
}

export fn kmp_skip_search(input_opt: ?[*]const i64, length: usize) i64 {
    const input = input_opt orelse return -1;
    if (length < 2 or length > MAX_INPUT_LENGTH) return -1;
    return execute(input[0..length]) orelse -1;
}
