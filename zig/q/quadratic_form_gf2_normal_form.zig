// Uncompiled bounded GF(2) quadratic normal-form draft.
const std = @import("std");

fn bit(value: u128, index: usize) bool {
    return ((value >> @as(u7, @intCast(index))) & 1) != 0;
}
fn evaluate(rows: *const [100]u128, n: usize, x: u128, y: u128) u1 {
    var answer: u1 = 0;
    for (0..n) |i| if (bit(x, i)) {
        answer ^= @intCast(@popCount(rows[i] & y) & 1);
    };
    return answer;
}

export fn quadratic_form_gf2_normal_form(input: [*c]const i64, length: usize,
    output: [*c]u8, capacity: usize) i64 {
    if (input == null or length == 0 or length > 202 or input[0] < 1 or input[0] > 100) return -1;
    const n: usize = @intCast(input[0]);
    const words = (n + 62) / 63;
    if (length != 1 + n * words) return -1;
    var upper = [_]u128{0} ** 100;
    var bilinear = [_]u128{0} ** 100;
    for (0..n) |i| {
        for (0..words) |chunk| {
            const raw = input[1 + i * words + chunk];
            if (raw < 0) return -1;
            for (0..63) |b| {
                if ((@as(u64, @intCast(raw)) >> @as(u6, @intCast(b))) & 1 == 0) continue;
                const j = 63 * chunk + b;
                if (j >= n or j < i) return -1;
                upper[i] |= @as(u128, 1) << @as(u7, @intCast(j));
                if (i != j) {
                    bilinear[i] |= @as(u128, 1) << @as(u7, @intCast(j));
                    bilinear[j] |= @as(u128, 1) << @as(u7, @intCast(i));
                }
            }
        }
    }
    const row_bytes = (n + 7) / 8;
    const needed = 3 + n * row_bytes;
    if (output == null or capacity < needed) return -2;
    var remaining = [_]u128{0} ** 100;
    var hyper = [_]u128{0} ** 100;
    var anis = [_]u128{0} ** 100;
    var columns = [_]u128{0} ** 100;
    for (0..n) |i| remaining[i] = @as(u128, 1) << @as(u7, @intCast(i));
    var count = n;
    var hc: usize = 0;
    var ac: usize = 0;
    while (true) {
        var left = count;
        var right = count;
        outer: for (0..count) |i| {
            for (i + 1..count) |j| {
                if (evaluate(&bilinear, n, remaining[i], remaining[j]) != 0) {
                    left = i; right = j; break :outer;
                }
            }
        }
        if (left == count) break;
        var u = remaining[left];
        var v = remaining[right];
        var rest = [_]u128{0} ** 100;
        var next: usize = 0;
        for (remaining[0..count], 0..) |w, index| {
            if (index == left or index == right) continue;
            var x = w;
            if (evaluate(&bilinear, n, w, v) != 0) x ^= u;
            if (evaluate(&bilinear, n, w, u) != 0) x ^= v;
            rest[next] = x; next += 1;
        }
        remaining = rest; count = next;
        const qu = evaluate(&upper, n, u, u);
        const qv = evaluate(&upper, n, v, v);
        if (qu != 0 and qv != 0) {
            anis[ac] = u; anis[ac + 1] = v; ac += 2;
        } else {
            if (qu != 0) { u ^= v; } else if (qv != 0) { v ^= u; }
            hyper[hc] = u; hyper[hc + 1] = v; hc += 2;
        }
    }
    while (ac >= 4) {
        const a = anis[ac - 2]; const b = anis[ac - 1];
        const c = anis[ac - 4]; const d = anis[ac - 3]; ac -= 4;
        const f = d ^ a ^ b;
        hyper[hc] = a ^ c; hyper[hc + 1] = b ^ c;
        hyper[hc + 2] = f; hyper[hc + 3] = f ^ c; hc += 4;
    }
    var has_linear = false;
    var linear: u128 = 0;
    for (0..count) |i| {
        if (evaluate(&upper, n, remaining[i], remaining[i]) == 0) continue;
        linear = remaining[i]; has_linear = true;
        for (i + 1..count) |j| remaining[j - 1] = remaining[j];
        count -= 1; break;
    }
    if (has_linear) {
        for (0..count) |i| {
            if (evaluate(&upper, n, remaining[i], remaining[i]) != 0) remaining[i] ^= linear;
        }
        if (ac != 0) {
            hyper[hc] = anis[0] ^ linear; hyper[hc + 1] = anis[1] ^ linear;
            hc += 2; ac = 0;
        }
    }
    var used: usize = 0;
    for (hyper[0..hc]) |x| { columns[used] = x; used += 1; }
    for (anis[0..ac]) |x| { columns[used] = x; used += 1; }
    if (has_linear) { columns[used] = linear; used += 1; }
    for (remaining[0..count]) |x| { columns[used] = x; used += 1; }
    if (used != n or hc % 2 != 0 or (ac != 0 and ac != 2)) return -4;
    var matrix = [_]u128{0} ** 100;
    var inverse = [_]u128{0} ** 100;
    for (0..n) |i| {
        inverse[i] = @as(u128, 1) << @as(u7, @intCast(i));
        for (0..n) |j| if (bit(columns[j], i)) {
            matrix[i] |= @as(u128, 1) << @as(u7, @intCast(j));
        };
    }
    for (0..n) |col| {
        var pivot = col;
        while (pivot < n and !bit(matrix[pivot], col)) : (pivot += 1) {}
        if (pivot == n) return -4;
        std.mem.swap(u128, &matrix[col], &matrix[pivot]);
        std.mem.swap(u128, &inverse[col], &inverse[pivot]);
        for (0..n) |row| if (row != col and bit(matrix[row], col)) {
            matrix[row] ^= matrix[col]; inverse[row] ^= inverse[col];
        };
    }
    var staged = [_]u8{0} ** 1303;
    staged[0] = @intCast(hc / 2); staged[1] = @intCast(ac / 2);
    staged[2] = if (has_linear) 1 else 0;
    for (0..n) |i| for (0..n) |j| {
        if (bit(inverse[i], j)) staged[3 + i * row_bytes + j / 8] |= @as(u8, 1) << @as(u3, @intCast(j % 8));
    };
    @memcpy(output[0..needed], staged[0..needed]);
    return @intCast(needed);
}
