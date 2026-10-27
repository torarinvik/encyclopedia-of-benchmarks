const MAX_N: usize = 32;
const MAX_Q: usize = 32;
const BUCKET: usize = 3;
const MAX_B: usize = 11;
const MAX_WORDS: usize = 100;

fn lcp(a: u16, b: u16) i64 {
    var count: i64 = 0;
    while (count < 16 and ((a >> @intCast(15 - count)) & 1) == ((b >> @intCast(15 - count)) & 1)) : (count += 1) {}
    return count;
}
fn putI64(out: [*]u8, pos: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |b| out[pos + b] = @truncate(bits >> @intCast(8 * b));
}

export fn mmpfh_bucketing(input: ?[*]const i64, length: usize, output: ?[*]u8, capacity: usize) i64 {
    const values = input orelse return -1;
    if (length < 3 or length > 66) return -1;
    const n0 = values[0]; const q0 = values[1];
    if (n0 < 1 or n0 > MAX_N or q0 < 1 or q0 > MAX_Q or length != 2 + @as(usize, @intCast(n0 + q0))) return -1;
    const n: usize = @intCast(n0); const q: usize = @intCast(q0);
    var keys: [MAX_N]u16 = undefined;
    var queries: [MAX_Q]u16 = undefined;
    for (0..n) |i| {
        const x = values[2 + i];
        if (x < 0 or x > 65535 or (i > 0 and @as(i64, keys[i - 1]) >= x)) return -1;
        keys[i] = @intCast(x);
    }
    for (0..q) |i| {
        const x = values[2 + n + i];
        if (x < 0 or x > 65535) return -1;
        queries[i] = @intCast(x);
        var found = false;
        for (0..n) |j| if (keys[j] == queries[i]) { found = true; };
        if (!found) return -1;
    }
    const buckets = (n + BUCKET - 1) / BUCKET;
    var d0: [MAX_N]i64 = undefined;
    var lens: [MAX_B]i64 = undefined;
    var prefixes: [MAX_B]i64 = undefined;
    var ranks: [MAX_Q]i64 = undefined;
    for (0..buckets) |b| {
        const start = b * BUCKET;
        const end = @min(start + BUCKET, n);
        const plen: i64 = if (end - start == 1) 16 else lcp(keys[start], keys[end - 1]);
        const prefix: i64 = if (plen == 0) 0 else @as(i64, keys[start]) >> @intCast(16 - plen);
        lens[b] = plen; prefixes[b] = prefix;
        for (start..end) |i| d0[i] = plen;
    }
    for (0..q) |i| {
        var pos: usize = 0;
        while (keys[pos] != queries[i]) : (pos += 1) {}
        const plen = d0[pos];
        const prefix: i64 = if (plen == 0) 0 else @as(i64, queries[i]) >> @intCast(16 - plen);
        var b: usize = 0;
        while (b < buckets and (lens[b] != plen or prefixes[b] != prefix)) : (b += 1) {}
        if (b == buckets) return -1;
        ranks[i] = @intCast(b * BUCKET + pos - b * BUCKET);
    }
    const words = 3 + n + 3 * buckets + q;
    const out = output orelse return -2;
    if (capacity < words * 8) return -2;
    var staged: [MAX_WORDS]i64 = [_]i64{0} ** MAX_WORDS;
    var k: usize = 0;
    staged[k] = @intCast(n); k += 1; staged[k] = @intCast(buckets); k += 1; staged[k] = @intCast(q); k += 1;
    for (0..n) |i| { staged[k] = d0[i]; k += 1; }
    for (0..buckets) |b| { staged[k] = lens[b]; k += 1; staged[k] = prefixes[b]; k += 1; staged[k] = @intCast(b); k += 1; }
    for (0..q) |i| { staged[k] = ranks[i]; k += 1; }
    for (0..words) |i| putI64(out, i * 8, staged[i]);
    return @intCast(words * 8);
}
