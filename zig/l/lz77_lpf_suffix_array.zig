const max_text: usize = 32;
const max_input: usize = 34;
const max_output: usize = 512;

fn suffix_less(text: [*]const i64, n: usize, a0: usize, b0: usize) bool {
    var a = a0;
    var b = b0;
    while (a < n and b < n) {
        if (text[a] != text[b]) return text[a] < text[b];
        a += 1;
        b += 1;
    }
    return a == n and b != n;
}

fn lcp(text: [*]const i64, n: usize, source: i64, target: usize) usize {
    if (source < 0) return 0;
    var length: usize = 0;
    const p: usize = @intCast(source);
    while (target + length < n and text[p + length] == text[target + length]) : (length += 1) {}
    return length;
}

fn put64(out: [*]u8, at: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |i| out[at + i] = @truncate(bits >> @intCast(i * 8));
}

export fn lz77_lpf_suffix_array(input_opt: ?[*]const i64, len: usize,
                                output_opt: ?[*]u8, capacity: usize) i64 {
    if (len < 1 or len > max_input) return -1;
    const input = input_opt orelse return -1;
    if (input[0] < 0 or input[0] > max_text) return -1;
    const n: usize = @intCast(input[0]);
    if (len != n + 1) return -1;
    var text = [_]i64{0} ** max_text;
    for (0..n) |i| {
        if (input[i + 1] < 0 or input[i + 1] > 255) return -1;
        text[i] = input[i + 1];
    }

    var sa = [_]usize{0} ** max_text;
    var inverse = [_]usize{0} ** max_text;
    var stack = [_]usize{0} ** max_text;
    var previous = [_]i64{-1} ** max_text;
    var following = [_]i64{-1} ** max_text;
    for (0..n) |i| sa[i] = i;
    for (1..n) |i| {
        const value = sa[i];
        var j = i;
        while (j > 0 and suffix_less(&text, n, value, sa[j - 1])) {
            sa[j] = sa[j - 1];
            j -= 1;
        }
        sa[j] = value;
    }
    for (0..n) |rank| inverse[sa[rank]] = rank;
    var top: usize = 0;
    for (0..n) |rank| {
        while (top > 0 and sa[stack[top - 1]] > sa[rank]) top -= 1;
        if (top > 0) previous[rank] = @intCast(stack[top - 1]);
        stack[top] = rank;
        top += 1;
    }
    top = 0;
    var rr = n;
    while (rr > 0) {
        rr -= 1;
        while (top > 0 and sa[stack[top - 1]] > sa[rr]) top -= 1;
        if (top > 0) following[rr] = @intCast(stack[top - 1]);
        stack[top] = rr;
        top += 1;
    }

    var staged = [_]u8{0} ** max_output;
    var pairs: usize = 0;
    var pos: usize = 0;
    while (pos < n) {
        const rank = inverse[pos];
        const psv: i64 = if (previous[rank] >= 0) @intCast(sa[@intCast(previous[rank])]) else -1;
        const nsv: i64 = if (following[rank] >= 0) @intCast(sa[@intCast(following[rank])]) else -1;
        const lp = lcp(&text, n, psv, pos);
        const ln = lcp(&text, n, nsv, pos);
        var source = psv;
        const matched = if (ln > lp) ln else lp;
        if (ln > lp) source = nsv;
        if (matched == 0) source = -1;
        put64(&staged, pairs * 16, source);
        put64(&staged, pairs * 16 + 8, @intCast(matched));
        pairs += 1;
        pos += if (matched > 0) matched else 1;
    }
    const bytes = pairs * 16;
    const output = output_opt orelse return -2;
    if (capacity < bytes) return -2;
    if (bytes > 0) @memcpy(output[0..bytes], staged[0..bytes]);
    return @intCast(bytes);
}
