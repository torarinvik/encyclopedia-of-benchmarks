// Uncompiled suffix-automaton minimum-rotation draft.
export fn suffix_automaton_minimum_rotation(input: ?[*]const i64, length: usize,
    output: ?[*]u8, capacity: usize) i64 {
    const ptr = input orelse return -1;
    if (length < 2 or length > 258) return -1;
    const values = ptr[0..length];
    const raw_n = values[0];
    if (raw_n < 1 or raw_n > 256 or length != @as(usize,@intCast(raw_n))+1) return -1;
    const n: usize = @intCast(raw_n);
    for (values[1..]) |v| if (v < 0 or v > 255) { return -1; };
    const out_ptr = output orelse return -2;
    if (capacity < n) return -2;
    const out = out_ptr[0..n];
    var next = [_]i32{-1} ** 262144;
    var links = [_]i32{-1} ** 1024;
    var lengths = [_]i32{0} ** 1024;
    var count: usize = 1; var last: usize = 0;
    for (0..2*n) |i| {
        const symbol: usize = @intCast(values[1+i%n]);
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
    var state: usize = 0;
    for (out) |*byte| {
        var symbol: usize = 0;
        while (next[state*256+symbol] < 0) symbol += 1;
        byte.* = @intCast(symbol);
        state = @intCast(next[state*256+symbol]);
    }
    return raw_n;
}
