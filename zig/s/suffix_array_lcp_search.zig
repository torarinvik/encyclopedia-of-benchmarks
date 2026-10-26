const MAX_N: usize = 32;
const MAX_M: usize = 16;
const MAX_INPUT: usize = 50;
const MAX_OUTPUT: usize = 264;

const PatternCompare = struct { cmp: i32, matched: usize };

fn suffixCmp(text: [MAX_N]i64, a: usize, b: usize, n: usize) i32 {
    var k: usize = 0;
    while (a + k < n and b + k < n) : (k += 1) {
        if (text[a + k] < text[b + k]) return -1;
        if (text[a + k] > text[b + k]) return 1;
    }
    if (a + k == n and b + k == n) return 0;
    return if (a + k == n) -1 else 1;
}

fn patternCmp(text: [MAX_N]i64, start: usize, n: usize,
    pattern: [MAX_M]i64, m: usize, offset: usize, prefix_equal: bool) PatternCompare {
    var matched = offset;
    while (matched < m and start + matched < n and text[start + matched] == pattern[matched]) : (matched += 1) {}
    if (matched == m) {
        if (prefix_equal or start + matched == n) return .{ .cmp = 0, .matched = matched };
        return .{ .cmp = 1, .matched = matched };
    }
    if (start + matched == n) return .{ .cmp = -1, .matched = matched };
    return .{ .cmp = if (text[start + matched] < pattern[matched]) -1 else 1, .matched = matched };
}

fn buildIntervals(n: usize, lcp: [MAX_N]usize,
    left_q: *[MAX_N * MAX_N]usize, right_q: *[MAX_N * MAX_N]usize) void {
    var lo_stack: [2 * MAX_N]usize = @splat(0);
    var hi_stack: [2 * MAX_N]usize = @splat(0);
    var top: usize = 1;
    lo_stack[0] = 0;
    hi_stack[0] = n - 1;
    while (top > 0) {
        top -= 1;
        const lo = lo_stack[top];
        const hi = hi_stack[top];
        if (hi - lo < 2) continue;
        const mid = (lo + hi + 1) / 2;
        var q = n + 1;
        var k = lo;
        while (k < mid) : (k += 1) { if (lcp[k] < q) q = lcp[k]; }
        left_q[lo * MAX_N + hi] = q;
        q = n + 1;
        k = mid;
        while (k < hi) : (k += 1) { if (lcp[k] < q) q = lcp[k]; }
        right_q[lo * MAX_N + hi] = q;
        if (hi - mid >= 2) { lo_stack[top] = mid; hi_stack[top] = hi; top += 1; }
        if (mid - lo >= 2) { lo_stack[top] = lo; hi_stack[top] = mid; top += 1; }
    }
}

fn bound(text: [MAX_N]i64, n: usize, pattern: [MAX_M]i64, m: usize,
    suffix: [MAX_N]usize, left_q: [MAX_N * MAX_N]usize,
    right_q: [MAX_N * MAX_N]usize, prefix_equal: bool) usize {
    const first = patternCmp(text, suffix[0], n, pattern, m, 0, prefix_equal);
    if (first.cmp > 0 or (!prefix_equal and first.cmp == 0)) return 0;
    const last = patternCmp(text, suffix[n - 1], n, pattern, m, 0, prefix_equal);
    if (last.cmp < 0 or (prefix_equal and last.cmp == 0)) return n;
    var l = first.matched;
    var r = last.matched;
    var lo: usize = 0;
    var hi = n - 1;
    while (hi - lo > 1) {
        const mid = (lo + hi + 1) / 2;
        if (l == r) {
            const result = patternCmp(text, suffix[mid], n, pattern, m, l, prefix_equal);
            if (result.cmp > 0 or (!prefix_equal and result.cmp == 0)) { hi = mid; r = result.matched; }
            else { lo = mid; l = result.matched; }
        } else if (l > r) {
            const q = left_q[lo * MAX_N + hi];
            if (l < q) { lo = mid; }
            else if (l > q) { hi = mid; r = q; }
            else {
                const result = patternCmp(text, suffix[mid], n, pattern, m, l, prefix_equal);
                if (result.cmp > 0 or (!prefix_equal and result.cmp == 0)) { hi = mid; r = result.matched; }
                else { lo = mid; l = result.matched; }
            }
        } else {
            const q = right_q[lo * MAX_N + hi];
            if (r < q) { hi = mid; }
            else if (r > q) { lo = mid; l = q; }
            else {
                const result = patternCmp(text, suffix[mid], n, pattern, m, r, prefix_equal);
                if (result.cmp > 0 or (!prefix_equal and result.cmp == 0)) { hi = mid; r = result.matched; }
                else { lo = mid; l = result.matched; }
            }
        }
    }
    return hi;
}

fn putI64Le(output: [*c]u8, offset: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |byte| {
        const shift: u6 = @intCast(byte * 8);
        output[offset + byte] = @truncate(bits >> shift);
    }
}

export fn suffix_array_lcp_search(values: [*c]const i64, length: usize,
    output: [*c]u8, output_capacity: usize) i64 {
    if (values == null or length < 3 or length > MAX_INPUT) return -1;
    if (values[0] < 1 or values[0] > @as(i64, @intCast(MAX_N))) return -1;
    const n: usize = @intCast(values[0]);
    if (length < n + 2 or values[n + 1] < 1 or values[n + 1] > @as(i64, @intCast(MAX_M))) return -1;
    const m: usize = @intCast(values[n + 1]);
    if (length != n + m + 2) return -1;
    var text: [MAX_N]i64 = @splat(0);
    var pattern: [MAX_M]i64 = @splat(0);
    var suffix: [MAX_N]usize = @splat(0);
    var lcp: [MAX_N]usize = @splat(0);
    var left_q: [MAX_N * MAX_N]usize = @splat(0);
    var right_q: [MAX_N * MAX_N]usize = @splat(0);
    for (0..n) |i| {
        text[i] = values[1 + i];
        if (text[i] < 0 or text[i] > 127) return -1;
        suffix[i] = i;
    }
    for (0..m) |i| {
        pattern[i] = values[n + 2 + i];
        if (pattern[i] < 0 or pattern[i] > 127) return -1;
    }
    for (1..n) |i| {
        const key = suffix[i];
        var j = i;
        while (j > 0 and suffixCmp(text, key, suffix[j - 1], n) < 0) {
            suffix[j] = suffix[j - 1];
            j -= 1;
        }
        suffix[j] = key;
    }
    for (0..n - 1) |i| {
        const a = suffix[i];
        const b = suffix[i + 1];
        var k: usize = 0;
        while (a + k < n and b + k < n and text[a + k] == text[b + k]) : (k += 1) {}
        lcp[i] = k;
    }
    buildIntervals(n, lcp, &left_q, &right_q);
    const first = bound(text, n, pattern, m, suffix, left_q, right_q, false);
    const last = bound(text, n, pattern, m, suffix, left_q, right_q, true);
    const count = last - first;
    const bytes = 8 * (count + 1);
    if (output == null or output_capacity < bytes) return -2;
    var staged: [MAX_OUTPUT]u8 = @splat(0);
    putI64Le(&staged, 0, @intCast(count));
    for (0..count) |i| putI64Le(&staged, 8 * (i + 1), @intCast(suffix[first + i]));
    for (0..bytes) |i| output[i] = staged[i];
    return @intCast(bytes);
}
