const std = @import("std");

fn tswCross(ax: i64, ay: i64, bx: i64, by: i64, px: i64, py: i64) i64 {
    return (bx - ax) * (py - ay) - (by - ay) * (px - ax);
}
fn tswSame(a: usize, b: usize, c: usize, d: usize) bool {
    return (a == c and b == d) or (a == d and b == c);
}
fn tswOn(ax: i64, ay: i64, bx: i64, by: i64, px: i64, py: i64) bool {
    return tswCross(ax, ay, bx, by, px, py) == 0 and px >= @min(ax, bx) and px <= @max(ax, bx) and py >= @min(ay, by) and py <= @max(ay, by);
}
fn tswIntersect(ax: i64, ay: i64, bx: i64, by: i64, cx: i64, cy: i64, dx: i64, dy: i64) bool {
    const o1 = tswCross(ax, ay, bx, by, cx, cy);
    const o2 = tswCross(ax, ay, bx, by, dx, dy);
    const o3 = tswCross(cx, cy, dx, dy, ax, ay);
    const o4 = tswCross(cx, cy, dx, dy, bx, by);
    if ((o1 == 0 and tswOn(ax, ay, bx, by, cx, cy)) or (o2 == 0 and tswOn(ax, ay, bx, by, dx, dy)) or
        (o3 == 0 and tswOn(cx, cy, dx, dy, ax, ay)) or (o4 == 0 and tswOn(cx, cy, dx, dy, bx, by))) return true;
    return ((o1 < 0 and o2 > 0) or (o1 > 0 and o2 < 0)) and ((o3 < 0 and o4 > 0) or (o3 > 0 and o4 < 0));
}

export fn triangulation_stochastic_visibility_walk(input_opt: ?[*]const i64, length: usize) i64 {
    const input = input_opt orelse return -1;
    if (length < 8 or length > 57) return -1;
    const vr = input[0]; const br = input[1]; const tr = input[2]; const sr = input[3];
    const px = input[4]; const py = input[5]; const capr = input[6]; const kr = input[7];
    if (vr < 3 or vr > 6 or br < 3 or br > vr or tr != 2 * vr - br - 2 or tr < 1 or tr > 7 or
        sr < 0 or sr >= tr or capr < 0 or capr > 12 or kr < 0 or kr > 12 or
        px < -200 or px > 200 or py < -200 or py > 200) return -1;
    const v: usize = @intCast(vr); const bcount: usize = @intCast(br); const tcount: usize = @intCast(tr);
    const start: usize = @intCast(sr); const cap: usize = @intCast(capr); const k: usize = @intCast(kr);
    if (length != 8 + 2 * v + bcount + 3 * tcount + k) return -1;

    var xs: [6]i64 = .{0} ** 6; var ys: [6]i64 = .{0} ** 6;
    var boundary: [6]usize = .{0} ** 6; var faces: [21]usize = .{0} ** 21;
    var neighbors: [21]i64 = .{-1} ** 21; var used: [6]bool = .{false} ** 6;
    var cursor: usize = 8;
    for (0..v) |i| {
        xs[i] = input[cursor]; ys[i] = input[cursor + 1]; cursor += 2;
        if (xs[i] < -200 or xs[i] > 200 or ys[i] < -200 or ys[i] > 200) return -1;
        for (0..i) |j| if (xs[i] == xs[j] and ys[i] == ys[j]) { return -1; };
    }
    for (0..bcount) |i| {
        const raw = input[cursor]; cursor += 1;
        if (raw < 0 or raw >= vr) return -1;
        boundary[i] = @intCast(raw);
        for (0..i) |j| if (boundary[i] == boundary[j]) { return -1; };
    }
    for (0..bcount) |i| {
        const a = boundary[i]; const b = boundary[(i + 1) % bcount];
        for (0..bcount) |j| {
            const c = boundary[j];
            if (c != a and c != b and tswCross(xs[a], ys[a], xs[b], ys[b], xs[c], ys[c]) <= 0) return -1;
        }
    }
    for (0..v) |p| {
        var on_boundary = false;
        for (0..bcount) |j| if (boundary[j] == p) { on_boundary = true; };
        if (!on_boundary) for (0..bcount) |j| {
            const a = boundary[j]; const b = boundary[(j + 1) % bcount];
            if (tswCross(xs[a], ys[a], xs[b], ys[b], xs[p], ys[p]) <= 0) return -1;
        };
    }
    var area_sum: i64 = 0;
    for (0..tcount) |f| {
        for (0..3) |e| {
            const raw = input[cursor]; cursor += 1;
            if (raw < 0 or raw >= vr) return -1;
            faces[f * 3 + e] = @intCast(raw);
        }
        const a = faces[f * 3]; const b = faces[f * 3 + 1]; const c = faces[f * 3 + 2];
        if (a == b or b == c or c == a or tswCross(xs[a], ys[a], xs[b], ys[b], xs[c], ys[c]) <= 0) return -1;
        used[a] = true; used[b] = true; used[c] = true;
        area_sum += tswCross(xs[a], ys[a], xs[b], ys[b], xs[c], ys[c]);
        for (0..f) |g| {
            var same = true;
            for (0..3) |e| {
                var found = false;
                for (0..3) |j| if (faces[f * 3 + e] == faces[g * 3 + j]) { found = true; };
                if (!found) same = false;
            }
            if (same) return -1;
        }
    }
    for (0..v) |i| if (!used[i]) { return -1; };
    var polygon_area: i64 = 0;
    for (0..bcount) |i| {
        const a = boundary[i]; const b = boundary[(i + 1) % bcount];
        polygon_area += xs[a] * ys[b] - ys[a] * xs[b];
    }
    if (polygon_area <= 0 or polygon_area != area_sum) return -1;
    for (0..bcount) |i| {
        const a = boundary[i]; const b = boundary[(i + 1) % bcount]; var owners: usize = 0;
        for (0..tcount) |f| for (0..3) |e| {
            if (tswSame(a, b, faces[f * 3 + e], faces[f * 3 + (e + 1) % 3])) owners += 1;
        };
        if (owners != 1) return -1;
    }
    for (0..tcount) |f| for (0..3) |e| {
        const a = faces[f * 3 + e]; const b = faces[f * 3 + (e + 1) % 3];
        var first = true;
        for (0..f + 1) |g| for (0..3) |ge| {
            if (g == f and ge >= e) continue;
            if (tswSame(a, b, faces[g * 3 + ge], faces[g * 3 + (ge + 1) % 3])) first = false;
        };
        if (first) {
            for (0..v) |p| if (p != a and p != b and tswOn(xs[a], ys[a], xs[b], ys[b], xs[p], ys[p])) { return -1; };
            for (f..tcount) |g| for (0..3) |ge| {
                if (g == f and ge <= e) continue;
                const c = faces[g * 3 + ge]; const d = faces[g * 3 + (ge + 1) % 3];
                if (a == c or a == d or b == c or b == d) continue;
                if (tswIntersect(xs[a], ys[a], xs[b], ys[b], xs[c], ys[c], xs[d], ys[d])) return -1;
            };
        }
    };
    for (0..tcount) |f| for (0..3) |e| {
        const a = faces[f * 3 + e]; const b = faces[f * 3 + (e + 1) % 3];
        var boundary_edge = false;
        for (0..bcount) |i| if (tswSame(a, b, boundary[i], boundary[(i + 1) % bcount])) { boundary_edge = true; };
        var owners: usize = 0; var other: i64 = -1; var first_u: usize = 0; var first_v: usize = 0;
        for (0..tcount) |g| for (0..3) |ge| {
            if (tswSame(a, b, faces[g * 3 + ge], faces[g * 3 + (ge + 1) % 3])) {
                if (owners == 0) { first_u = faces[g * 3 + ge]; first_v = faces[g * 3 + (ge + 1) % 3]; }
                else if (faces[g * 3 + ge] != first_v or faces[g * 3 + (ge + 1) % 3] != first_u) return -1;
                owners += 1; if (g != f) other = @intCast(g);
            }
        };
        if (owners != (if (boundary_edge) 1 else 2)) return -1;
        if (!boundary_edge) neighbors[f * 3 + e] = other;
    };
    for (0..k) |i| if (input[cursor + i] < 0 or input[cursor + i] > 1) { return -1; };
    for (0..bcount) |i| {
        const a = boundary[i]; const b = boundary[(i + 1) % bcount];
        if (tswCross(xs[a], ys[a], xs[b], ys[b], px, py) <= 0) return -1;
    }
    var containing: usize = 0;
    for (0..tcount) |f| {
        const a = faces[f * 3]; const b = faces[f * 3 + 1]; const c = faces[f * 3 + 2];
        if (tswCross(xs[a], ys[a], xs[b], ys[b], px, py) > 0 and tswCross(xs[b], ys[b], xs[c], ys[c], px, py) > 0 and tswCross(xs[c], ys[c], xs[a], ys[a], px, py) > 0) containing += 1;
    }
    if (containing != 1) return -1;

    var face = start; var steps: usize = 0; var choice_index: usize = 0;
    var trace: i64 = @intCast(face + 1); var predicates: i64 = 0; var status: i64 = 0;
    while (true) {
        const a = faces[face * 3]; const b = faces[face * 3 + 1]; const c = faces[face * 3 + 2];
        const eu = [_]usize{a, b, c}; const ev = [_]usize{b, c, a};
        var eligible: [3]usize = .{0} ** 3; var count: usize = 0;
        for (0..3) |e| {
            predicates += 1;
            if (tswCross(xs[eu[e]], ys[eu[e]], xs[ev[e]], ys[ev[e]], px, py) < 0) { eligible[count] = e; count += 1; }
        }
        if (count == 0) { status = 0; break; }
        if (steps == cap) { status = 2; break; }
        var selected: usize = 0;
        if (count == 1) { selected = eligible[0]; }
        else if (count == 2) {
            if (choice_index == k) { status = 1; break; }
            selected = eligible[@intCast(input[cursor + choice_index])]; choice_index += 1;
        } else return -1;
        if (neighbors[face * 3 + selected] < 0) return -1;
        face = @intCast(neighbors[face * 3 + selected]); steps += 1; trace = trace * 9 + @as(i64, @intCast(face + 1));
    }
    return (trace * 40 + predicates) * 3 + status;
}
