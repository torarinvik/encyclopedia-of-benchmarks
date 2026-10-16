fn read16(p: [*c]u8, i: usize) usize { return @as(usize, p[i]) + (@as(usize, p[i + 1]) << 8); }
fn write16(p: [*c]u8, i: usize, x: usize) { p[i] = @truncate(x); p[i + 1] = @truncate(x >> 8); }
fn letter(x: i64) bool { return (x >= 65 and x <= 90) or (x >= 97 and x <= 122); }
fn operator(x: i64) bool { return x == 43 or x == 45 or x == 42 or x == 47 or x == 94; }
export fn postfix_to_infix(v: [*c]const i64, n: usize, out: [*c]u8, cap: usize) i64 {
    if (v == null or n < 1 or n > 65 or v[0] < 0 or v[0] > 64 or n != @as(usize, @intCast(v[0])) + 1) return -1;
    if (out == null or cap < 8192) return -2;
    const count: usize = @intCast(v[0]); if (count == 0) return 0;
    if (count == 1) { if (!letter(v[1])) return -1; out[0] = @intCast(v[1]); return 1; }
    var stack: usize = 0; var scratch: usize = 256;
    for (0..count) |i| {
        const x = v[i + 1];
        if (operator(x)) {
            if (stack < 2) return -1;
            const l = stack - 2; const r = stack - 1;
            const ls = read16(out, l * 4); const ll = read16(out, l * 4 + 2);
            const rs = read16(out, r * 4); const rl = read16(out, r * 4 + 2);
            const start = scratch; out[scratch] = 40; scratch += 1;
            for (0..ll) |j| { out[scratch] = out[ls + j]; scratch += 1; }
            out[scratch] = @intCast(x); scratch += 1;
            for (0..rl) |j| { out[scratch] = out[rs + j]; scratch += 1; }
            out[scratch] = 41; scratch += 1;
            write16(out, l * 4, start); write16(out, l * 4 + 2, scratch - start); stack -= 1;
        } else {
            if (!letter(x)) return -1;
            write16(out, stack * 4, scratch); write16(out, stack * 4 + 2, 1); out[scratch] = @intCast(x); scratch += 1; stack += 1;
        }
        if (scratch > cap) return -2;
    }
    if (stack != 1) return -1;
    const start = read16(out, 0); const size = read16(out, 2);
    for (0..size) |i| { out[i] = out[start + i]; }
    return @intCast(size);
}
