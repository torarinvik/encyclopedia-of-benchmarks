// Uncompiled and unexecuted Zig resultant draft.
const std = @import("std");
const Allocator = std.mem.Allocator;
const P: i64 = 998244353;
const Poly = []i64;
const Head = struct { degree: usize, leading: i64 };
const Matrix = struct { a: Poly, b: Poly, c: Poly, d: Poly };
const Pair = struct { x: Poly, y: Poly };

fn power(value: i64, exponent_value: usize) i64 {
    var x = value;
    var n = exponent_value;
    var y: i64 = 1;
    while (n != 0) : (n >>= 1) {
        if ((n & 1) != 0) y = @rem(y * x, P);
        x = @rem(x * x, P);
    }
    return y;
}

fn trim(a: Poly) Poly {
    var n = a.len;
    while (n > 0 and a[n - 1] == 0) n -= 1;
    return a[0..n];
}

fn ntt(a: Poly, inverse: bool) void {
    var j: usize = 0;
    for (1..a.len) |i| {
        var bit = a.len >> 1;
        while ((j & bit) != 0) { j ^= bit; bit >>= 1; }
        j ^= bit;
        if (i < j) std.mem.swap(i64, &a[i], &a[j]);
    }
    var width: usize = 2;
    while (width <= a.len) : (width *= 2) {
        var root = power(3, @as(usize, @intCast(P - 1)) / width);
        if (inverse) root = power(root, @intCast(P - 2));
        var start: usize = 0;
        while (start < a.len) : (start += width) {
            var factor: i64 = 1;
            for (0..width / 2) |k| {
                const x = a[start + k];
                const y = @rem(a[start + k + width / 2] * factor, P);
                a[start + k] = @rem(x + y, P);
                a[start + k + width / 2] = @rem(x - y + P, P);
                factor = @rem(factor * root, P);
            }
        }
    }
    if (inverse) {
        const scale = power(@intCast(a.len), @intCast(P - 2));
        for (a) |*x| x.* = @rem(x.* * scale, P);
    }
}

fn zeros(alloc: Allocator, n: usize) !Poly {
    const a = try alloc.alloc(i64, n);
    @memset(a, 0);
    return a;
}

fn mul(alloc: Allocator, a: []const i64, b: []const i64) !Poly {
    if (a.len == 0 or b.len == 0) return zeros(alloc, 0);
    const count = a.len + b.len - 1;
    const out = try zeros(alloc, count);
    if (@min(a.len, b.len) <= 32) {
        for (a, 0..) |x, i| for (b, 0..) |y, j| { out[i+j] = @rem(out[i+j] + x*y, P); };
    } else {
        var size: usize = 1;
        while (size < count) size *= 2;
        const x = try zeros(alloc, size);
        const y = try zeros(alloc, size);
        @memcpy(x[0..a.len], a); @memcpy(y[0..b.len], b);
        ntt(x, false); ntt(y, false);
        for (0..size) |i| x[i] = @rem(x[i]*y[i], P);
        ntt(x, true);
        @memcpy(out, x[0..count]);
    }
    return trim(out);
}

fn add(alloc: Allocator, a: []const i64, b: []const i64) !Poly {
    const out = try zeros(alloc, @max(a.len, b.len));
    for (a, 0..) |x, i| out[i] = x;
    for (b, 0..) |x, i| out[i] = @rem(out[i] + x, P);
    return trim(out);
}

fn inverseSeries(alloc: Allocator, f: []const i64, count: usize) !Poly {
    var inv = try zeros(alloc, 1);
    inv[0] = power(f[0], @intCast(P - 2));
    while (inv.len < count) {
        const size = @min(count, 2 * inv.len);
        const product = try mul(alloc, f[0..@min(size, f.len)], inv);
        const correction = try zeros(alloc, size);
        for (0..size) |i| {
            const x = if (i < product.len) product[i] else 0;
            correction[i] = @rem(P - x, P);
        }
        correction[0] = @rem(correction[0] + 2, P);
        const update = try mul(alloc, inv, correction);
        inv = try zeros(alloc, size);
        @memcpy(inv[0..@min(size, update.len)], update[0..@min(size, update.len)]);
    }
    return inv;
}

fn divrem(alloc: Allocator, a: []const i64, b: []const i64) !Pair {
    if (a.len < b.len) return .{ .x = try zeros(alloc, 0), .y = try alloc.dupe(i64, a) };
    const count = a.len - b.len + 1;
    const high = try zeros(alloc, count);
    const reversed = try zeros(alloc, b.len);
    for (0..count) |i| high[i] = a[a.len - 1 - i];
    for (0..b.len) |i| reversed[i] = b[b.len - 1 - i];
    const inv = try inverseSeries(alloc, reversed, count);
    const qr = try mul(alloc, high, inv);
    const q = try zeros(alloc, count);
    for (0..count) |i| {
        const index = count - 1 - i;
        if (index < qr.len) q[i] = qr[index];
    }
    const removed = try mul(alloc, q, b);
    const r = try zeros(alloc, b.len - 1);
    for (0..r.len) |i| r[i] = @rem(a[i] - (if (i < removed.len) removed[i] else 0) + P, P);
    return .{ .x = trim(q), .y = trim(r) };
}

fn identity(alloc: Allocator) !Matrix {
    const a = try zeros(alloc, 1); a[0] = 1;
    const d = try zeros(alloc, 1); d[0] = 1;
    return .{ .a = a, .b = try zeros(alloc, 0), .c = try zeros(alloc, 0), .d = d };
}

fn step(alloc: Allocator, q: []const i64) !Matrix {
    const b = try zeros(alloc, 1); b[0] = 1;
    const c = try zeros(alloc, 1); c[0] = 1;
    const d = try zeros(alloc, q.len);
    for (q, 0..) |x, i| d[i] = @rem(P - x, P);
    return .{ .a = try zeros(alloc, 0), .b = b, .c = c, .d = d };
}

fn dot(alloc: Allocator, a: []const i64, b: []const i64, c: []const i64, d: []const i64) !Poly {
    return add(alloc, try mul(alloc, a, b), try mul(alloc, c, d));
}

fn compose(alloc: Allocator, x: Matrix, y: Matrix) !Matrix {
    return .{ .a = try dot(alloc,x.a,y.a,x.b,y.c), .b = try dot(alloc,x.a,y.b,x.b,y.d),
              .c = try dot(alloc,x.c,y.a,x.d,y.c), .d = try dot(alloc,x.c,y.b,x.d,y.d) };
}

fn apply(alloc: Allocator, m: Matrix, a: []const i64, b: []const i64) !Pair {
    return .{ .x = try dot(alloc,m.a,a,m.b,b), .y = try dot(alloc,m.c,a,m.d,b) };
}

fn upper(a: []const i64, shift: usize) []const i64 { return a[@min(shift, a.len)..]; }

fn half(alloc: Allocator, a: []const i64, b: []const i64, heads: []Head, count: *usize) Allocator.Error!Matrix {
    if (b.len == 0) return identity(alloc);
    const degree = a.len - 1;
    const threshold = (degree + 1) / 2;
    if (b.len <= threshold) return identity(alloc);
    if (degree <= 64) {
        var x = a;
        var y = b;
        var matrix = try identity(alloc);
        while (y.len > threshold and y.len > 0) {
            const division = try divrem(alloc, x, y);
            heads[count.*] = .{ .degree = division.x.len - 1, .leading = division.x[division.x.len - 1] };
            count.* += 1;
            matrix = try compose(alloc, try step(alloc, division.x), matrix);
            x = y; y = division.y;
        }
        return matrix;
    }
    const first = try half(alloc, upper(a,threshold), upper(b,threshold), heads, count);
    const reduced = try apply(alloc, first, a, b);
    if (reduced.y.len == 0 or reduced.y.len <= threshold) return first;
    const division = try divrem(alloc, reduced.x, reduced.y);
    heads[count.*] = .{ .degree = division.x.len - 1, .leading = division.x[division.x.len - 1] };
    count.* += 1;
    const prefix = try compose(alloc, try step(alloc, division.x), first);
    if (division.y.len == 0) return prefix;
    const shift = 2 * threshold - (reduced.y.len - 1);
    if (division.y.len <= shift) return prefix;
    return compose(alloc, try half(alloc, upper(reduced.y,shift), upper(division.y,shift), heads, count), prefix);
}

fn resultant(alloc: Allocator, first: []const i64, second: []const i64) !i64 {
    var a = first;
    var b = second;
    var answer: i64 = 1;
    if (a.len < b.len) {
        if (((a.len-1) & 1) != 0 and ((b.len-1) & 1) != 0) answer = P-answer;
        std.mem.swap([]const i64, &a, &b);
    }
    const heads = try alloc.alloc(Head, a.len + 1);
    while (true) {
        if (b.len == 1) return @rem(answer * power(b[0], a.len-1), P);
        var count: usize = 0;
        var reduced: ?Pair = null;
        if (a.len != b.len) {
            const matrix = try half(alloc, a, b, heads, &count);
            if (count != 0) reduced = try apply(alloc, matrix, a, b);
        }
        if (reduced) |pair| {
            if (pair.y.len == 0) return 0;
            var da = a.len-1;
            var db = b.len-1;
            var lead = b[b.len-1];
            for (0..count) |i| {
                const last = i+1 == count;
                const dr = if (last) pair.y.len-1 else db-heads[i+1].degree;
                if ((da & 1) != 0 and (db & 1) != 0) answer = P-answer;
                answer = @rem(answer * power(lead, da-dr), P);
                if (!last) lead = @rem(lead * power(heads[i+1].leading, @intCast(P-2)), P);
                da = db; db = dr;
            }
            a = pair.x; b = pair.y;
        } else {
            const division = try divrem(alloc, a, b);
            if (division.y.len == 0) return 0;
            const da = a.len-1;
            const db = b.len-1;
            const dr = division.y.len-1;
            if ((da & 1) != 0 and (db & 1) != 0) answer = P-answer;
            answer = @rem(answer * power(b[b.len-1], da-dr), P);
            a = b; b = division.y;
        }
    }
}

export fn polynomial_resultant_half_gcd(input_opt: ?[*]const i64, length: usize) i64 {
    if (input_opt == null or length < 4 or length > 100002) return -1;
    const input = input_opt.?;
    const m = input[0];
    const n = input[1];
    if (m < 0 or m > 50000 or n < 0 or n > 50000 or m+n > 99998) return -1;
    const first_count: usize = @as(usize, @intCast(m)) + 1;
    const second_count: usize = @as(usize, @intCast(n)) + 1;
    if (length != first_count + second_count + 2) return -1;
    for (2..length) |i| if (input[i] < 0 or input[i] >= P) { return -1; };
    if (input[1+first_count] == 0 or input[length-1] == 0) return -1;
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    return resultant(arena.allocator(), input[2..2+first_count], input[2+first_count..length]) catch -1;
}
