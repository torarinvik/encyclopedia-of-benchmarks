const MAX_N: usize = 64;
const MAX_K: usize = 4;
const MAX_INPUT: usize = 67;
const MAX_OUTPUT: usize = 320;
const LEVELS: usize = 7;

fn pairLess(a: usize, b: usize, width: usize, rank: *const [MAX_N]i32, n: usize) bool {
    if (rank.*[a] != rank.*[b]) return rank.*[a] < rank.*[b];
    const ra: i32 = if (a + width < n) rank.*[a + width] else -1;
    const rb: i32 = if (b + width < n) rank.*[b + width] else -1;
    return ra < rb;
}

fn lce(a: usize, b: usize, n: usize, inverse: *const [MAX_N]usize,
    sparse: *const [LEVELS * MAX_N]usize, logs: *const [MAX_N + 1]usize) usize {
    if (a >= n or b >= n) return 0;
    if (a == b) return n - a;
    var left = inverse.*[a];
    var right = inverse.*[b];
    if (left > right) { const temporary = left; left = right; right = temporary; }
    left += 1;
    const count = right - left + 1;
    const level = logs.*[count];
    const span = @as(usize, 1) << @intCast(level);
    return @min(sparse.*[level * MAX_N + left], sparse.*[level * MAX_N + right - span + 1]);
}

export fn k_mismatch_longest_extension_table(values: [*c]const i64, length: usize,
    output: [*c]u8, capacity: usize) i64 {
    if (values == null or length < 3 or length > MAX_INPUT) return -1;
    if (values[0] < 1 or values[0] > @as(i64, @intCast(MAX_N))
        or values[1] < 0 or values[1] > @as(i64, @intCast(MAX_K))) return -1;
    const n: usize = @intCast(values[0]);
    const budget: usize = @intCast(values[1]);
    if (length != n + 2) return -1;

    var text = [_]i32{0} ** MAX_N;
    var suffixes = [_]usize{0} ** MAX_N;
    var rank = [_]i32{0} ** MAX_N;
    var inverse = [_]usize{0} ** MAX_N;
    var lcp_values = [_]usize{0} ** MAX_N;
    var sparse = [_]usize{0} ** (LEVELS * MAX_N);
    var logs = [_]usize{0} ** (MAX_N + 1);
    var staged = [_]u8{0} ** MAX_OUTPUT;
    for (0..n) |i| {
        if (values[i + 2] < 0 or values[i + 2] > 25) return -1;
        text[i] = @intCast(values[i + 2]);
        suffixes[i] = i;
        rank[i] = text[i];
    }

    var width: usize = 1;
    while (width < n) {
        for (1..n) |i| {
            const key = suffixes[i];
            var j = i;
            while (j > 0 and pairLess(key, suffixes[j - 1], width, &rank, n)) {
                suffixes[j] = suffixes[j - 1];
                j -= 1;
            }
            suffixes[j] = key;
        }
        var next_rank = [_]i32{0} ** MAX_N;
        var classes: usize = 0;
        next_rank[suffixes[0]] = 0;
        for (1..n) |i| {
            const a = suffixes[i - 1];
            const b = suffixes[i];
            const a2: i32 = if (a + width < n) rank[a + width] else -1;
            const b2: i32 = if (b + width < n) rank[b + width] else -1;
            if (rank[a] != rank[b] or a2 != b2) classes += 1;
            next_rank[b] = @intCast(classes);
        }
        rank = next_rank;
        if (classes == n - 1 or width > n / 2) break;
        width *= 2;
    }

    for (0..n) |i| inverse[suffixes[i]] = i;
    var matched: usize = 0;
    for (0..n) |start| {
        const order = inverse[start];
        if (order == 0) { matched = 0; continue; }
        const other = suffixes[order - 1];
        while (start + matched < n and other + matched < n and text[start + matched] == text[other + matched]) : (matched += 1) {}
        lcp_values[order] = matched;
        if (matched > 0) matched -= 1;
    }
    for (0..n) |i| sparse[i] = lcp_values[i];
    for (1..LEVELS) |level| {
        const span = @as(usize, 1) << @intCast(level);
        const half = span / 2;
        var i: usize = 0;
        while (i + span <= n) : (i += 1)
            sparse[level * MAX_N + i] = @min(sparse[(level - 1) * MAX_N + i], sparse[(level - 1) * MAX_N + i + half]);
    }
    for (2..n + 1) |count| logs[count] = logs[count / 2] + 1;

    var written: usize = 0;
    for (0..n) |p| {
        const limit = n - p;
        var extension = @min(limit, lce(0, p, n, &inverse, &sparse, &logs));
        staged[written] = @intCast(extension);
        written += 1;
        var k: usize = 1;
        while (k <= budget) : (k += 1) {
            if (extension < limit)
                extension = @min(limit, extension + 1 + lce(extension + 1, p + extension + 1, n, &inverse, &sparse, &logs));
            staged[written] = @intCast(extension);
            written += 1;
        }
    }
    if (written > MAX_OUTPUT) return -1;
    if (output == null or capacity < written) return -2;
    for (0..written) |i| output[i] = staged[i];
    return @intCast(written);
}
