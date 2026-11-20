// Independently authored draft; not compiled or run.
const Line = struct { a: i64, b: i64, c: i64 };
const Vertex = struct { x: i64, y: i64, den: i64, incoming: usize };

fn abs64(x: i64) i64 { return if (x < 0) -x else x; }
fn gcd(a0: i64, b0: i64) i64 {
    var a = abs64(a0); var b = abs64(b0);
    while (b != 0) { const r = @mod(a, b); a = b; b = r; }
    return a;
}
fn intersect(a: Line, b: Line) ?Vertex {
    var d = a.a * b.b - b.a * a.b;
    if (d == 0) return null;
    var x = a.c * b.b - a.b * b.c;
    var y = a.a * b.c - a.c * b.a;
    if (d < 0) { d = -d; x = -x; y = -y; }
    const g = gcd(gcd(x, y), d);
    return .{ .x = @divTrunc(x, g), .y = @divTrunc(y, g), .den = @divTrunc(d, g), .incoming = 0 };
}
fn side(l: Line, p: Vertex) i64 { return l.a * p.x + l.b * p.y - l.c * p.den; }
fn same(a: Vertex, b: Vertex) bool {
    return a.x * b.den == b.x * a.den and a.y * b.den == b.y * a.den;
}
fn turn(a: Vertex, b: Vertex, c: Vertex) i64 {
    const dx1 = b.x * a.den - a.x * b.den; const dy1 = b.y * a.den - a.y * b.den;
    const dx2 = c.x * b.den - b.x * c.den; const dy2 = c.y * b.den - b.y * c.den;
    return dx1 * dy2 - dy1 * dx2;
}
fn append(out: *[32]Vertex, count: *usize, p: Vertex) void {
    if (count.* == 0 or !same(out[count.* - 1], p)) { out[count.*] = p; count.* += 1; }
}
fn put(out: [*]u8, offset: *usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |b| { out[offset.*] = @truncate(bits >> @as(u6, @intCast(8 * b))); offset.* += 1; }
}

export fn half_plane_intersection_incremental_clipping(input_opt: ?[*]const i64, length: usize,
    output_opt: ?[*]u8, capacity: usize) i64 {
    if (input_opt == null or length < 1 or length > 38) return -1;
    const input = input_opt.?;
    if (input[0] < 0 or input[0] > 12) return -1;
    const n: usize = @intCast(input[0]);
    if (length != 1 + 3 * n) return -1;
    var lines: [16]Line = @splat(.{ .a = 0, .b = 0, .c = 0 });
    lines[0] = .{ .a = -1, .b = 0, .c = 256 };
    lines[1] = .{ .a = 0, .b = -1, .c = 256 };
    lines[2] = .{ .a = 1, .b = 0, .c = 256 };
    lines[3] = .{ .a = 0, .b = 1, .c = 256 };
    for (0..n) |i| {
        const a = input[1 + 3 * i]; const b = input[2 + 3 * i]; const c = input[3 + 3 * i];
        if (a < -16 or a > 16 or b < -16 or b > 16 or c < -128 or c > 128
            or (a == 0 and b == 0) or gcd(a, b) != 1) return -1;
        lines[4 + i] = .{ .a = a, .b = b, .c = c };
    }
    var polygon: [32]Vertex = undefined;
    polygon[0] = .{ .x = -256, .y = -256, .den = 1, .incoming = 0 };
    polygon[1] = .{ .x = 256, .y = -256, .den = 1, .incoming = 1 };
    polygon[2] = .{ .x = 256, .y = 256, .den = 1, .incoming = 2 };
    polygon[3] = .{ .x = -256, .y = 256, .den = 1, .incoming = 3 };
    var count: usize = 4;
    for (4..4 + n) |line| {
        if (count < 3) break;
        var next: [32]Vertex = undefined; var used: usize = 0;
        for (0..count) |i| {
            const s = polygon[(i + count - 1) % count]; const e = polygon[i];
            const s_in = side(lines[line], s) <= 0; const e_in = side(lines[line], e) <= 0;
            if (s_in != e_in) {
                var p = intersect(lines[e.incoming], lines[line]) orelse return -1;
                p.incoming = if (s_in) e.incoming else line;
                append(&next, &used, p);
            }
            if (e_in) append(&next, &used, e);
        }
        if (used > 1 and same(next[0], next[used - 1])) {
            next[0].incoming = next[used - 1].incoming; used -= 1;
        }
        count = used;
        for (0..count) |i| polygon[i] = next[i];
        var noncollinear = false;
        if (count >= 3) {
            for (0..count) |i| {
                if (turn(polygon[i], polygon[(i + 1) % count], polygon[(i + 2) % count]) != 0) noncollinear = true;
            }
        }
        if (!noncollinear) count = 0;
    }
    var changed = true;
    while (changed and count >= 3) {
        changed = false;
        for (0..count) |i| {
            if (turn(polygon[(i + count - 1) % count], polygon[i], polygon[(i + 1) % count]) == 0) {
                var j = i;
                while (j + 1 < count) : (j += 1) polygon[j] = polygon[j + 1];
                count -= 1; changed = true; break;
            }
        }
    }
    if (count < 3) count = 0;
    var first: usize = 0;
    if (count > 0) {
        for (1..count) |i| {
            const yi = polygon[i].y * polygon[first].den; const yf = polygon[first].y * polygon[i].den;
            if (yi < yf or (yi == yf and polygon[i].x * polygon[first].den < polygon[first].x * polygon[i].den)) first = i;
        }
    }
    const needed = (1 + 4 * count) * 8;
    if (output_opt == null or capacity < needed) return -2;
    const output = output_opt.?; var offset: usize = 0;
    put(output, &offset, @intCast(count));
    for (0..count) |i| {
        const p = polygon[(first + i) % count];
        const gx = gcd(p.x, p.den); const gy = gcd(p.y, p.den);
        put(output, &offset, @divTrunc(p.x, gx)); put(output, &offset, @divTrunc(p.den, gx));
        put(output, &offset, @divTrunc(p.y, gy)); put(output, &offset, @divTrunc(p.den, gy));
    }
    return @intCast(needed);
}
