const Summary = struct { value: i64 = 0, count: usize = 0 };
fn merge(a: Summary, b: Summary) Summary {
    if (a.count == 0) return b;
    if (b.count == 0) return a;
    if (a.value == b.value) return .{ .value = a.value, .count = a.count+b.count };
    if (a.count >= b.count) return .{ .value = a.value, .count = a.count-b.count };
    return .{ .value = b.value, .count = b.count-a.count };
}
fn slot(value: i64, names: *[128]i64, size: *usize) usize {
    for (0..size.*) |i| { if (names[i] == value) return i; }
    const result = size.*; names[result] = value; size.* += 1; return result;
}
fn prefix(pos: usize) u64 {
    if (pos == 64) return ~@as(u64, 0);
    return (@as(u64, 1) << @as(u6, @intCast(pos)))-1;
}
pub export fn dynamic_range_majority(input: [*c]const i64, length: usize,
                                      output: [*c]u8, capacity: usize) i64 {
    if (input == null or length < 2 or length > 258) return -1;
    if (input[0] < 1 or input[0] > 64 or input[1] < 1 or input[1] > 64) return -1;
    const n: usize = @intCast(input[0]); const q: usize = @intCast(input[1]);
    if (length != 2+n+3*q) return -1;
    for (0..n) |i| { if (input[2+i] < 0 or input[2+i] > 1000000000) return -1; }
    var queries: usize = 0;
    for (0..q) |i| {
        const b = 2+n+3*i;
        if (input[b] == 0) {
            if (input[b+1] < 0 or input[b+1] >= @as(i64,@intCast(n)) or input[b+2] < 0 or input[b+2] > 1000000000) return -1;
        } else if (input[b] == 1) {
            if (input[b+1] < 0 or input[b+1] >= input[b+2] or input[b+2] > @as(i64,@intCast(n))) return -1;
            queries += 1;
        } else return -1;
    }
    if (queries == 0) return -1;
    if (output == null or capacity < 8*queries) return -2;
    var tree: [128]Summary = @splat(.{});
    var names: [128]i64 = @splat(0);
    var masks: [128]u64 = @splat(0);
    var data: [64]i64 = @splat(0);
    var distinct: usize = 0;
    for (0..n) |i| {
        data[i] = input[2+i]; tree[64+i] = .{ .value = data[i], .count = 1 };
        const s = slot(data[i],&names,&distinct);
        masks[s] |= @as(u64,1) << @as(u6,@intCast(i));
    }
    var node: usize = 63;
    while (node > 0) : (node -= 1) tree[node] = merge(tree[2*node],tree[2*node+1]);
    var written: usize = 0;
    for (0..q) |i| {
        const b = 2+n+3*i;
        if (input[b] == 0) {
            const p: usize = @intCast(input[b+1]); const value = input[b+2];
            const old = slot(data[p],&names,&distinct); const fresh = slot(value,&names,&distinct);
            const bit = @as(u64,1) << @as(u6,@intCast(p));
            masks[old] &= ~bit; masks[fresh] |= bit; data[p] = value;
            node = 64+p; tree[node] = .{ .value = value, .count = 1 };
            while (node > 1) { node /= 2; tree[node] = merge(tree[2*node],tree[2*node+1]); }
        } else {
            const lo: usize = @intCast(input[b+1]); const hi: usize = @intCast(input[b+2]);
            var l = lo+64; var r = hi+64; var a = Summary{}; var z = Summary{};
            while (l < r) {
                if (l & 1 != 0) { a = merge(a,tree[l]); l += 1; }
                if (r & 1 != 0) { r -= 1; z = merge(tree[r],z); }
                l /= 2; r /= 2;
            }
            const candidate = merge(a,z);
            var answer: i64 = -1;
            if (candidate.count > 0) {
                const s = slot(candidate.value,&names,&distinct);
                const bits = masks[s] & (prefix(hi)^prefix(lo));
                if (2*@as(usize,@intCast(@popCount(bits))) > hi-lo) answer = candidate.value;
            }
            const encoded: u64 = @bitCast(answer);
            for (0..8) |byte| output[8*written+byte] = @truncate(encoded >> @as(u6,@intCast(8*byte)));
            written += 1;
        }
    }
    return @intCast(8*written);
}
