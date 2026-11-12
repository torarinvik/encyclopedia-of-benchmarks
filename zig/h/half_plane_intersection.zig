const MAX_LINES: usize = 16;
const MAX_INPUT: usize = 37;
const BOX_LIMIT: i64 = 256;

const Halfplane = struct { a: i64, b: i64, c: i64 };
const Point = struct { x: i64, y: i64, den: i64 };

fn abs64(x: i64) i64 { return if (x < 0) -x else x; }
fn gcd64(a0: i64, b0: i64) i64 {
    var a = abs64(a0); var b = abs64(b0);
    while (b != 0) { const r = @mod(a, b); a = b; b = r; }
    return a;
}
fn angle_half(h: Halfplane) u8 { return if (h.b > 0 or (h.b == 0 and h.a >= 0)) 0 else 1; }
fn line_less(x: Halfplane, y: Halfplane) bool {
    const hx = angle_half(x); const hy = angle_half(y);
    if (hx != hy) return hx < hy;
    const turn = x.a * y.b - x.b * y.a;
    if (turn != 0) return turn > 0;
    return x.c < y.c;
}
fn intersect(x: Halfplane, y: Halfplane) ?Point {
    var det = x.a * y.b - y.a * x.b;
    if (det == 0) return null;
    var xn = x.c * y.b - x.b * y.c;
    var yn = x.a * y.c - x.c * y.a;
    if (det < 0) { det = -det; xn = -xn; yn = -yn; }
    const g = gcd64(gcd64(xn, yn), det);
    return .{ .x = @divTrunc(xn, g), .y = @divTrunc(yn, g), .den = @divTrunc(det, g) };
}
fn outside(h: Halfplane, p: Point) bool { return h.a * p.x + h.b * p.y > h.c * p.den; }
fn same_point(x: Point, y: Point) bool { return x.x * y.den == y.x * x.den and x.y * y.den == y.y * x.den; }
fn orient(a: Point, b: Point, c: Point) i64 {
    const dx1 = b.x * a.den - a.x * b.den; const dy1 = b.y * a.den - a.y * b.den;
    const dx2 = c.x * b.den - b.x * c.den; const dy2 = c.y * b.den - b.y * c.den;
    return dx1 * dy2 - dy1 * dx2;
}
fn less_yx(a: Point, b: Point) bool {
    const y1 = a.y * b.den; const y2 = b.y * a.den;
    return if (y1 != y2) y1 < y2 else a.x * b.den < b.x * a.den;
}
fn put_i64(out: [*]u8, offset: *usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |b| { out[offset.*] = @truncate(bits >> @as(u6, @intCast(8 * b))); offset.* += 1; }
}

export fn half_plane_intersection(input_opt: ?[*]const i64, length: usize,
    output_opt: ?[*]u8, capacity: usize) i64 {
    if (input_opt == null or length < 1 or length > MAX_INPUT) return -1;
    const input = input_opt.?;
    if (input[0] < 0 or input[0] > 12) return -1;
    const count: usize = @intCast(input[0]);
    if (length != 1 + 3 * count) return -1;
    var lines: [MAX_LINES]Halfplane = @splat(.{ .a = 0, .b = 0, .c = 0 });
    var queue: [MAX_LINES]Halfplane = @splat(.{ .a = 0, .b = 0, .c = 0 });
    var points: [MAX_LINES]Point = @splat(.{ .x = 0, .y = 0, .den = 1 });
    var clean: [MAX_LINES]Point = @splat(.{ .x = 0, .y = 0, .den = 1 });
    var line_count: usize = 0;
    for (0..count) |i| {
        const a = input[1 + 3 * i]; const b = input[2 + 3 * i]; const c = input[3 + 3 * i];
        if (a < -16 or a > 16 or b < -16 or b > 16 or c < -128 or c > 128
                or (a == 0 and b == 0) or gcd64(a, b) != 1) return -1;
        lines[line_count] = .{ .a = a, .b = b, .c = c }; line_count += 1;
    }
    lines[line_count] = .{ .a = 1, .b = 0, .c = BOX_LIMIT }; line_count += 1;
    lines[line_count] = .{ .a = 0, .b = 1, .c = BOX_LIMIT }; line_count += 1;
    lines[line_count] = .{ .a = -1, .b = 0, .c = BOX_LIMIT }; line_count += 1;
    lines[line_count] = .{ .a = 0, .b = -1, .c = BOX_LIMIT }; line_count += 1;
    for (1..line_count) |i| {
        const key = lines[i]; var j = i;
        while (j > 0 and line_less(key, lines[j - 1])) { lines[j] = lines[j - 1]; j -= 1; }
        lines[j] = key;
    }
    var reduced: usize = 0;
    for (0..line_count) |i| {
        if (reduced > 0 and lines[i].a == lines[reduced - 1].a and lines[i].b == lines[reduced - 1].b) continue;
        lines[reduced] = lines[i]; reduced += 1;
    }
    var head: usize = 0; var tail: usize = 0; var empty = false;
    for (0..reduced) |i| {
        const h = lines[i];
        while (tail - head > 1) {
            const p = intersect(queue[tail - 2], queue[tail - 1]) orelse break;
            if (!outside(h, p)) break;
            tail -= 1;
        }
        while (tail - head > 1) {
            const p = intersect(queue[head], queue[head + 1]) orelse break;
            if (!outside(h, p)) break;
            head += 1;
        }
        if (tail > head) {
            const last = queue[tail - 1];
            if (last.a * h.b - last.b * h.a == 0) {
                if (last.a * h.a + last.b * h.b < 0) { head = 0; tail = 0; empty = true; break; }
                if (h.c < last.c) queue[tail - 1] = h;
                continue;
            }
        }
        queue[tail] = h; tail += 1;
    }
    if (empty) { head = 0; tail = 0; }
    if (tail - head >= 3) {
        while (tail - head > 2) {
            const p = intersect(queue[tail - 2], queue[tail - 1]) orelse break;
            if (!outside(queue[head], p)) break;
            tail -= 1;
        }
        while (tail - head > 2) {
            const p = intersect(queue[head], queue[head + 1]) orelse break;
            if (!outside(queue[tail - 1], p)) break;
            head += 1;
        }
    }
    var point_count: usize = 0;
    if (tail - head >= 3) {
        var i = head;
        while (i < tail) : (i += 1) {
            const next = if (i + 1 == tail) head else i + 1;
            const p = intersect(queue[i], queue[next]) orelse { point_count = 0; break; };
            points[point_count] = p; point_count += 1;
        }
    }
    var clean_count: usize = 0;
    for (0..point_count) |i| {
        if (clean_count == 0 or !same_point(clean[clean_count - 1], points[i])) { clean[clean_count] = points[i]; clean_count += 1; }
    }
    if (clean_count > 1 and same_point(clean[0], clean[clean_count - 1])) clean_count -= 1;
    var changed = true;
    while (changed and clean_count >= 3) {
        changed = false;
        for (0..clean_count) |i| {
            const prev = (i + clean_count - 1) % clean_count; const next = (i + 1) % clean_count;
            if (orient(clean[prev], clean[i], clean[next]) == 0) {
                var j = i;
                while (j + 1 < clean_count) : (j += 1) clean[j] = clean[j + 1];
                clean_count -= 1; changed = true; break;
            }
        }
    }
    if (clean_count < 3) clean_count = 0;
    if (clean_count > 0) {
        var first: usize = 0;
        for (1..clean_count) |i| { if (less_yx(clean[i], clean[first])) first = i; }
        const old = clean;
        for (0..clean_count) |i| clean[i] = old[(first + i) % clean_count];
    }
    const needed = (1 + 4 * clean_count) * 8;
    if (needed > capacity or output_opt == null) return -2;
    const output = output_opt.?;
    var offset: usize = 0; put_i64(output, &offset, @intCast(clean_count));
    for (0..clean_count) |i| {
        const gx = gcd64(clean[i].x, clean[i].den); const gy = gcd64(clean[i].y, clean[i].den);
        put_i64(output, &offset, @divTrunc(clean[i].x, gx)); put_i64(output, &offset, @divTrunc(clean[i].den, gx));
        put_i64(output, &offset, @divTrunc(clean[i].y, gy)); put_i64(output, &offset, @divTrunc(clean[i].den, gy));
    }
    return @intCast(needed);
}
