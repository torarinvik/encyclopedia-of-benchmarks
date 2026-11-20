// Uncompiled monotone-cursor Prüfer decoder draft.
fn pdlWrite(output: []u8, offset: usize, value: usize) void {
    const bits: u64 = @intCast(value);
    for (0..8) |i| output[offset+i] = @truncate(bits >> @intCast(8*i));
}
export fn prufer_decode_linear(input: ?[*]const i64, length: usize, output: ?[*]u8, capacity: usize) i64 {
    const ptr = input orelse return -1;
    if (length < 1 or length > 4096) return -1;
    const values = ptr[0..length];
    const nv = values[0];
    if (nv < 2 or nv > 4096 or length != @as(usize,@intCast(nv))-1) return -1;
    const n: usize = @intCast(nv);
    var count = [_]i32{0} ** 4096;
    for (values[1..]) |raw| {
        if (raw < 0 or raw >= nv) return -1;
        count[@intCast(raw)] += 1;
    }
    const needed = 16*(n-1);
    const out_ptr = output orelse return -2;
    if (capacity < needed) return -2;
    const out = out_ptr[0..needed];
    var cursor = n-1;
    while (count[cursor] != 0) cursor -= 1;
    var leaf = cursor;
    for (values[1..], 0..) |raw, i| {
        const v: usize = @intCast(raw);
        pdlWrite(out, 16*i, leaf); pdlWrite(out, 16*i+8, v);
        count[leaf] = -1; count[v] -= 1;
        if (count[v] == 0 and v > cursor) { leaf = v; } else {
            cursor -= 1;
            while (count[cursor] != 0) cursor -= 1;
            leaf = cursor;
        }
    }
    var other: usize = 0;
    while (other == leaf or count[other] != 0) other += 1;
    pdlWrite(out, 16*(n-2), leaf); pdlWrite(out, 16*(n-2)+8, other);
    return @intCast(needed);
}
