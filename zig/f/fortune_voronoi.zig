const MAX_SITES: usize = 8;
const MAX_ARCS: usize = 2 * MAX_SITES - 1;
const MAX_VERTICES: usize = MAX_SITES + 3;
const MAX_OUTPUT_VALUES: usize = 369;
const EPS: f64 = 1.0e-10;

const Point = struct { x: f64, y: f64 };
const Arc = struct { site: i32, prev: i32, next: i32, active: bool };
const Circle = struct { y: f64, x: f64, arc: i32, left: i32, right: i32 };
const Rat = struct { n: i64, d: i64 };
const RPoint = struct { x: Rat, y: Rat };

fn absI64(value: i64) i64 {
    return if (value < 0) -value else value;
}

fn rat(numerator_input: i64, denominator_input: i64) Rat {
    var numerator = numerator_input;
    var denominator = denominator_input;
    if (denominator < 0) {
        numerator = -numerator;
        denominator = -denominator;
    }
    var a = absI64(numerator);
    var b = denominator;
    while (b != 0) {
        const remainder = @rem(a, b);
        a = b;
        b = remainder;
    }
    const divisor = if (a == 0) @as(i64, 1) else a;
    return .{ .n = @divTrunc(numerator, divisor), .d = @divTrunc(denominator, divisor) };
}

fn radd(a: Rat, b: Rat) Rat {
    return rat(a.n * b.d + b.n * a.d, a.d * b.d);
}

fn rsub(a: Rat, b: Rat) Rat {
    return rat(a.n * b.d - b.n * a.d, a.d * b.d);
}

fn rmul(a: Rat, b: Rat) Rat {
    return rat(a.n * b.n, a.d * b.d);
}

fn rdiv(a: Rat, b: Rat) Rat {
    return rat(a.n * b.d, a.d * b.n);
}

fn rcmp(a: Rat, b: Rat) i32 {
    const left = a.n * b.d;
    const right = b.n * a.d;
    if (left < right) return -1;
    if (left > right) return 1;
    return 0;
}

fn pointEqual(a: RPoint, b: RPoint) bool {
    return rcmp(a.x, b.x) == 0 and rcmp(a.y, b.y) == 0;
}

fn pointLess(a: RPoint, b: RPoint) bool {
    const x_order = rcmp(a.x, b.x);
    return x_order < 0 or (x_order == 0 and rcmp(a.y, b.y) < 0);
}

fn orient(a: Point, b: Point, c: Point) i32 {
    const value = (b.x - a.x) * (c.y - a.y) - (b.y - a.y) * (c.x - a.x);
    if (value > 0) return 1;
    if (value < 0) return -1;
    return 0;
}

fn breakpoint(p: Point, q: Point, line_y: f64) f64 {
    if (@abs(p.y - q.y) < EPS) return (p.x + q.x) * 0.5;
    const dp = p.y - line_y;
    const dq = q.y - line_y;
    const a = q.y - p.y;
    const b = -2.0 * p.x * dq + 2.0 * q.x * dp;
    const c = (p.x * p.x + p.y * p.y - line_y * line_y) * dq -
        (q.x * q.x + q.y * q.y - line_y * line_y) * dp;
    var discriminant = b * b - 4.0 * a * c;
    if (discriminant < 0.0 and discriminant > -EPS) discriminant = 0.0;
    const root = @sqrt(discriminant);
    const first = (-b - root) / (2.0 * a);
    const second = (-b + root) / (2.0 * a);
    return if (p.y < q.y) @max(first, second) else @min(first, second);
}

fn circle(a: Point, b: Point, c: Point, sweep_y: f64, arc: i32, left: i32, right: i32) ?Circle {
    if (orient(a, b, c) >= 0) return null;
    const aa = a.x * a.x + a.y * a.y;
    const bb = b.x * b.x + b.y * b.y;
    const cc = c.x * c.x + c.y * c.y;
    const denominator = 2.0 * (a.x * (b.y - c.y) + b.x * (c.y - a.y) + c.x * (a.y - b.y));
    if (@abs(denominator) < EPS) return null;
    const x = (aa * (b.y - c.y) + bb * (c.y - a.y) + cc * (a.y - b.y)) / denominator;
    const y = (aa * (c.x - b.x) + bb * (a.x - c.x) + cc * (b.x - a.x)) / denominator;
    const dx = x - a.x;
    const dy = y - a.y;
    const bottom = y - @sqrt(dx * dx + dy * dy);
    if (!(bottom < sweep_y - EPS)) return null;
    return .{ .y = bottom, .x = x, .arc = arc, .left = left, .right = right };
}

fn halfPlaneValue(point: RPoint, a: i64, b: i64, c: i64) Rat {
    return rsub(radd(rmul(rat(a, 1), point.x), rmul(rat(b, 1), point.y)), rat(c, 1));
}

fn intersection(p: RPoint, q: RPoint, dp: Rat, dq: Rat) RPoint {
    const t = rdiv(dp, rsub(dp, dq));
    return .{
        .x = radd(p.x, rmul(t, rsub(q.x, p.x))),
        .y = radd(p.y, rmul(t, rsub(q.y, p.y))),
    };
}

fn pushPoint(points: []RPoint, count: *usize, point: RPoint) void {
    if (count.* == 0 or !pointEqual(points[count.* - 1], point)) {
        points[count.*] = point;
        count.* += 1;
    }
}

fn clipPolygon(poly: []RPoint, count: usize, a: i64, b: i64, c: i64) usize {
    var next: [MAX_VERTICES]RPoint = undefined;
    var next_count: usize = 0;
    for (0..count) |index| {
        const p = poly[index];
        const q = poly[(index + 1) % count];
        const dp = halfPlaneValue(p, a, b, c);
        const dq = halfPlaneValue(q, a, b, c);
        const p_inside = dp.n <= 0;
        const q_inside = dq.n <= 0;
        if (p_inside and q_inside) {
            pushPoint(next[0..], &next_count, q);
        } else if (p_inside and !q_inside) {
            pushPoint(next[0..], &next_count, intersection(p, q, dp, dq));
        } else if (!p_inside and q_inside) {
            pushPoint(next[0..], &next_count, intersection(p, q, dp, dq));
            pushPoint(next[0..], &next_count, q);
        }
    }
    if (next_count > 1 and pointEqual(next[0], next[next_count - 1])) next_count -= 1;
    @memcpy(poly[0..next_count], next[0..next_count]);
    return next_count;
}

fn validInput(input: [*]const i64, site_count: usize) bool {
    for (0..site_count) |i| {
        const ax = input[1 + 2 * i];
        const ay = input[2 + 2 * i];
        for (i + 1..site_count) |j| {
            if (ax == input[1 + 2 * j] and ay == input[2 + 2 * j]) return false;
            if (ay == input[2 + 2 * j]) return false;
        }
    }
    for (0..site_count) |i| {
        for (i + 1..site_count) |j| {
            for (j + 1..site_count) |k| {
                const ax = input[1 + 2 * i];
                const ay = input[2 + 2 * i];
                const bx = input[1 + 2 * j];
                const by = input[2 + 2 * j];
                const cx = input[1 + 2 * k];
                const cy = input[2 + 2 * k];
                if ((bx - ax) * (cy - ay) == (by - ay) * (cx - ax)) return false;
            }
        }
    }
    for (0..site_count) |i| {
        for (i + 1..site_count) |j| {
            for (j + 1..site_count) |k| {
                for (k + 1..site_count) |l| {
                    const ax = input[1 + 2 * i] - input[1 + 2 * l];
                    const ay = input[2 + 2 * i] - input[2 + 2 * l];
                    const bx = input[1 + 2 * j] - input[1 + 2 * l];
                    const by = input[2 + 2 * j] - input[2 + 2 * l];
                    const cx = input[1 + 2 * k] - input[1 + 2 * l];
                    const cy = input[2 + 2 * k] - input[2 + 2 * l];
                    const aa = ax * ax + ay * ay;
                    const bb = bx * bx + by * by;
                    const cc = cx * cx + cy * cy;
                    const determinant = ax * (by * cc - bb * cy) - ay * (bx * cc - bb * cx) + aa * (bx * cy - by * cx);
                    if (determinant == 0) return false;
                }
            }
        }
    }
    return true;
}

fn putI64(output: [*]u8, slot: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |byte_index| output[slot * 8 + byte_index] = @truncate(bits >> @intCast(byte_index * 8));
}

export fn fortune_voronoi(input: [*c]const i64, length: usize, output: [*c]u8, capacity: usize) i64 {
    if (input == null or length < 3) return -1;
    const site_count_value = input[0];
    if (site_count_value < 1 or site_count_value > MAX_SITES) return -1;
    const site_count: usize = @intCast(site_count_value);
    if (length != 1 + 2 * site_count) return -1;
    for (0..site_count) |i| {
        if (input[1 + 2 * i] < -8 or input[1 + 2 * i] > 8 or input[2 + 2 * i] < -8 or input[2 + 2 * i] > 8) return -1;
    }
    if (!validInput(input, site_count)) return -1;

    var sites: [MAX_SITES]Point = undefined;
    var order: [MAX_SITES]usize = undefined;
    for (0..site_count) |i| {
        sites[i] = .{ .x = @floatFromInt(input[1 + 2 * i]), .y = @floatFromInt(input[2 + 2 * i]) };
        order[i] = i;
    }
    for (1..site_count) |i| {
        const value = order[i];
        var j = i;
        while (j > 0 and sites[order[j - 1]].y < sites[value].y) : (j -= 1) order[j] = order[j - 1];
        order[j] = value;
    }

    var arcs: [MAX_ARCS]Arc = undefined;
    var arc_count: usize = 1;
    var first: i32 = 0;
    arcs[0] = .{ .site = @intCast(order[0]), .prev = -1, .next = -1, .active = true };
    var next_site: usize = 1;
    var sweep_y = sites[order[0]].y;
    var adjacent: [MAX_SITES][MAX_SITES]bool = @splat(@splat(false));

    while (next_site < site_count or first >= 0) {
        var best: ?Circle = null;
        var arc_index = first;
        while (arc_index >= 0) {
            const current: usize = @intCast(arc_index);
            const left = arcs[current].prev;
            const right = arcs[current].next;
            if (left >= 0 and right >= 0) {
                const li: usize = @intCast(left);
                const ri: usize = @intCast(right);
                const a = @as(usize, @intCast(arcs[li].site));
                const b = @as(usize, @intCast(arcs[current].site));
                const c = @as(usize, @intCast(arcs[ri].site));
                if (a != b and b != c and a != c) {
                    if (circle(sites[a], sites[b], sites[c], sweep_y, arc_index, left, right)) |candidate| {
                        if (best == null or candidate.y > best.?.y + EPS or
                            (@abs(candidate.y - best.?.y) <= EPS and candidate.arc < best.?.arc)) best = candidate;
                    }
                }
            }
            arc_index = arcs[current].next;
        }

        const do_site = next_site < site_count and (best == null or sites[order[next_site]].y > best.?.y + EPS);
        if (!do_site and best == null) break;
        if (do_site) {
            const site = order[next_site];
            next_site += 1;
            sweep_y = sites[site].y;
            var arc = first;
            while (arcs[@intCast(arc)].next >= 0) {
                const right = arcs[@intCast(arc)].next;
                if (sites[site].x < breakpoint(sites[@intCast(arcs[@intCast(arc)].site)], sites[@intCast(arcs[@intCast(right)].site)], sweep_y)) break;
                arc = right;
            }
            const arc_u: usize = @intCast(arc);
            const old_next = arcs[arc_u].next;
            const old_site: usize = @intCast(arcs[arc_u].site);
            if (arc_count + 2 > MAX_ARCS) return -1;
            const middle: i32 = @intCast(arc_count);
            arc_count += 1;
            const right: i32 = @intCast(arc_count);
            arc_count += 1;
            arcs[@intCast(middle)] = .{ .site = @intCast(site), .prev = arc, .next = right, .active = true };
            arcs[@intCast(right)] = .{ .site = @intCast(old_site), .prev = middle, .next = old_next, .active = true };
            arcs[arc_u].next = middle;
            if (old_next >= 0) arcs[@intCast(old_next)].prev = right;
            adjacent[old_site][site] = true;
            adjacent[site][old_site] = true;
        } else {
            const event = best.?;
            const arc: usize = @intCast(event.arc);
            const left: usize = @intCast(event.left);
            const right: usize = @intCast(event.right);
            if (!arcs[arc].active or arcs[arc].prev != event.left or arcs[arc].next != event.right) return -1;
            sweep_y = event.y;
            const left_site: usize = @intCast(arcs[left].site);
            const right_site: usize = @intCast(arcs[right].site);
            adjacent[left_site][right_site] = true;
            adjacent[right_site][left_site] = true;
            arcs[left].next = event.right;
            arcs[right].prev = event.left;
            arcs[arc].active = false;
        }
    }

    var values: [MAX_OUTPUT_VALUES]i64 = undefined;
    var used: usize = 0;
    values[used] = @intCast(site_count);
    used += 1;
    for (0..site_count) |i| {
        var polygon: [MAX_VERTICES]RPoint = undefined;
        polygon[0] = .{ .x = .{ .n = -16, .d = 1 }, .y = .{ .n = -16, .d = 1 } };
        polygon[1] = .{ .x = .{ .n = 16, .d = 1 }, .y = .{ .n = -16, .d = 1 } };
        polygon[2] = .{ .x = .{ .n = 16, .d = 1 }, .y = .{ .n = 16, .d = 1 } };
        polygon[3] = .{ .x = .{ .n = -16, .d = 1 }, .y = .{ .n = 16, .d = 1 } };
        var count: usize = 4;
        for (0..site_count) |j| {
            if (!adjacent[i][j]) continue;
            const x = input[1 + 2 * j];
            const y = input[2 + 2 * j];
            const sx = input[1 + 2 * i];
            const sy = input[2 + 2 * i];
            count = clipPolygon(polygon[0..], count, 2 * (x - sx), 2 * (y - sy), x * x + y * y - sx * sx - sy * sy);
        }
        if (count < 3 or used + 2 + 4 * count > MAX_OUTPUT_VALUES) return -1;
        var start: usize = 0;
        for (1..count) |j| {
            if (pointLess(polygon[j], polygon[start])) start = j;
        }
        values[used] = @intCast(i);
        used += 1;
        values[used] = @intCast(count);
        used += 1;
        for (0..count) |j| {
            const point = polygon[(start + j) % count];
            values[used] = point.x.n;
            used += 1;
            values[used] = point.x.d;
            used += 1;
            values[used] = point.y.n;
            used += 1;
            values[used] = point.y.d;
            used += 1;
        }
    }

    const byte_count = used * 8;
    if (output == null or capacity < byte_count) return -2;
    for (0..used) |i| putI64(output, i, values[i]);
    return @intCast(byte_count);
}
