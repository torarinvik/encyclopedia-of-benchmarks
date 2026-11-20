// Independently authored draft; not compiled or run.
export fn suffix_automaton_kth_distinct_substring(input: ?[*]const i64, length: usize,
    output: ?[*]u8, capacity: usize) i64 {
    const ptr = input orelse return -1;
    if (length < 3 or length > 259) return -1;
    const values = ptr[0..length];
    const raw_n = values[0];
    var k = values[1];
    if (raw_n < 1 or raw_n > 256 or length != @as(usize,@intCast(raw_n))+2 or k < 1) return -1;
    const n: usize = @intCast(raw_n);
    for (values[2..]) |v| if (v < 0 or v > 255) { return -1; };
    var next = [_]i32{-1} ** 131072;
    var links = [_]i32{-1} ** 512;
    var lengths = [_]usize{0} ** 512;
    var paths = [_]i64{0} ** 512;
    var count: usize = 1;
    var last: usize = 0;
    for (values[2..]) |byte| {
        const symbol: usize = @intCast(byte);
        const current = count; count += 1;
        lengths[current] = lengths[last]+1;
        var p: i32 = @intCast(last);
        while (p >= 0 and next[@as(usize,@intCast(p))*256+symbol] < 0) {
            const slot = @as(usize,@intCast(p))*256+symbol;
            next[slot] = @intCast(current);
            p = links[@intCast(p)];
        }
        if (p < 0) links[current] = 0 else {
            const q: usize = @intCast(next[@as(usize,@intCast(p))*256+symbol]);
            if (lengths[@intCast(p)]+1 == lengths[q]) links[current] = @intCast(q) else {
                const clone = count; count += 1;
                for (0..256) |c| next[clone*256+c] = next[q*256+c];
                links[clone] = links[q]; lengths[clone] = lengths[@intCast(p)]+1;
                while (p >= 0 and next[@as(usize,@intCast(p))*256+symbol] == @as(i32,@intCast(q))) {
                    next[@as(usize,@intCast(p))*256+symbol] = @intCast(clone);
                    p = links[@intCast(p)];
                }
                links[q] = @intCast(clone); links[current] = @intCast(clone);
            }
        }
        last = current;
    }
    var buckets = [_]usize{0} ** 257;
    var order = [_]usize{0} ** 512;
    for (lengths[0..count]) |len| buckets[len] += 1;
    for (1..n+1) |i| buckets[i] += buckets[i-1];
    var i = count;
    while (i > 0) {
        i -= 1;
        const len = lengths[i];
        buckets[len] -= 1;
        order[buckets[len]] = i;
    }
    i = count;
    while (i > 0) {
        i -= 1;
        const state = order[i];
        for (0..256) |c| {
            const target = next[state*256+c];
            if (target >= 0) paths[state] += 1 + paths[@intCast(target)];
        }
    }
    if (k > paths[0]) return -1;
    var result = [_]u8{0} ** 256;
    var used: usize = 0;
    var state: usize = 0;
    while (true) {
        var found = false;
        for (0..256) |c| {
            const target = next[state*256+c];
            if (target < 0) continue;
            const destination: usize = @intCast(target);
            const group = 1 + paths[destination];
            if (k > group) { k -= group; continue; }
            result[used] = @intCast(c); used += 1; state = destination; found = true; break;
        }
        if (!found) return -1;
        if (k == 1) break;
        k -= 1;
    }
    const out = output orelse return -2;
    if (capacity < used) return -2;
    @memcpy(out[0..used], result[0..used]);
    return @intCast(used);
}
