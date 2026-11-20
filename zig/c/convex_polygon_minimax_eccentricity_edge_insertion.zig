const MIN_N: usize = 3;
const MAX_N: usize = 6;
const MAX_LENGTH: usize = 14;
const MAX_TRIANGLES: usize = 4;
const MAX_ALL: usize = 14;
const MAX_DIAGONALS: usize = 9;
const MAX_TRIPLES: usize = 20;

const Point = struct { x: i64, y: i64 };
const Triangle = struct { a: usize, b: usize, c: usize };
const Triangulation = struct {
    triangles: [MAX_TRIANGLES]Triangle,
    count: usize,
    edges: u64,
};
const Fraction = struct { num: i64, den: i64 };
const Metrics = struct { maximum: Fraction, worst: u64 };
const ScoredTriangle = struct { score: Fraction, sides: [3]i64 };

fn orient(p: [MAX_N]Point, a: usize, b: usize, c: usize) i64 {
    return (p[b].x - p[a].x) * (p[c].y - p[a].y) - (p[b].y - p[a].y) * (p[c].x - p[a].x);
}

fn abs64(value: i64) i64 {
    return if (value < 0) -value else value;
}

fn gcd64(left: i64, right: i64) i64 {
    var a = left;
    var b = right;
    while (b != 0) {
        const remainder = @rem(a, b);
        a = b;
        b = remainder;
    }
    return a;
}

fn makeFraction(num: i64, den: i64) Fraction {
    const divisor = gcd64(num, den);
    return .{ .num = @divTrunc(num, divisor), .den = @divTrunc(den, divisor) };
}

fn compare(left: Fraction, right: Fraction) i32 {
    const lhs = left.num * right.den;
    const rhs = right.num * left.den;
    return if (lhs < rhs) -1 else if (lhs > rhs) 1 else 0;
}

fn edgeBit(a: usize, b: usize) u64 {
    const low = @min(a, b);
    const high = @max(a, b);
    const shift: u6 = @intCast(low * MAX_N + high);
    return @as(u64, 1) << shift;
}

fn properCross(p: [MAX_N]Point, a: usize, b: usize, c: usize, d: usize) bool {
    return orient(p, a, b, c) * orient(p, a, b, d) < 0 and
        orient(p, c, d, a) * orient(p, c, d, b) < 0;
}

fn insideTriangle(p: [MAX_N]Point, t: Triangle, v: usize) bool {
    const direction = orient(p, t.a, t.b, t.c);
    return orient(p, t.a, t.b, v) * direction > 0 and
        orient(p, t.b, t.c, v) * direction > 0 and
        orient(p, t.c, t.a, v) * direction > 0;
}

fn hasEdge(edges: u64, a: usize, b: usize) bool {
    return (edges & edgeBit(a, b)) != 0;
}

fn triangleScore(p: [MAX_N]Point, t: Triangle) ScoredTriangle {
    const a = p[t.a];
    const b = p[t.b];
    const c = p[t.c];
    var sides = [3]i64{
        (b.x - c.x) * (b.x - c.x) + (b.y - c.y) * (b.y - c.y),
        (c.x - a.x) * (c.x - a.x) + (c.y - a.y) * (c.y - a.y),
        (a.x - b.x) * (a.x - b.x) + (a.y - b.y) * (a.y - b.y),
    };
    var largest: usize = 0;
    for (1..3) |index| if (sides[index] > sides[largest]) { largest = index; };
    const other = sides[0] + sides[1] + sides[2] - sides[largest];
    if (sides[largest] <= other) return .{ .score = .{ .num = 0, .den = 1 }, .sides = sides };
    const area = abs64(orient(p, t.a, t.b, t.c));
    const difference = sides[largest] - other;
    return .{
        .score = makeFraction(sides[largest] * difference * difference, 16 * area * area),
        .sides = sides,
    };
}

fn triangleId(t: Triangle, n: usize) usize {
    var id: usize = 0;
    for (0..n) |a| for (a + 1..n) |b| for (b + 1..n) |c| {
        if (a == t.a and b == t.b and c == t.c) return id;
        id += 1;
    };
    return 0;
}

fn evaluate(p: [MAX_N]Point, n: usize, triangulation: Triangulation) Metrics {
    var result = Metrics{ .maximum = .{ .num = 0, .den = 1 }, .worst = 0 };
    for (0..triangulation.count) |index| {
        const triangle = triangulation.triangles[index];
        const score = triangleScore(p, triangle).score;
        const bit = @as(u64, 1) << @as(u6, @intCast(triangleId(triangle, n)));
        const order = compare(score, result.maximum);
        if (order > 0) {
            result.maximum = score;
            result.worst = bit;
        } else if (order == 0) {
            result.worst |= bit;
        }
    }
    return result;
}

fn improves(candidate: Metrics, current: Metrics) bool {
    const order = compare(candidate.maximum, current.maximum);
    return order < 0 or (order == 0 and candidate.worst != current.worst and
        (candidate.worst & current.worst) == candidate.worst);
}

fn popCount(value: u64) usize {
    return @popCount(value);
}

fn preferable(candidate: Metrics, current: Metrics) bool {
    const order = compare(candidate.maximum, current.maximum);
    if (order != 0) return order < 0;
    const candidate_count = popCount(candidate.worst);
    const current_count = popCount(current.worst);
    return candidate_count < current_count or
        (candidate_count == current_count and candidate.worst < current.worst);
}

fn enumerate(p: [MAX_N]Point, n: usize, output: *[MAX_ALL]Triangulation) usize {
    var diagonal_a: [MAX_DIAGONALS]usize = undefined;
    var diagonal_b: [MAX_DIAGONALS]usize = undefined;
    var diagonal_count: usize = 0;
    for (0..n) |a| {
        for (a + 2..n) |b| {
            if (a == 0 and b == n - 1) continue;
            diagonal_a[diagonal_count] = a;
            diagonal_b[diagonal_count] = b;
            diagonal_count += 1;
        }
    }
    var boundary: u64 = 0;
    for (0..n) |a| boundary |= edgeBit(a, (a + 1) % n);
    const limit: usize = @as(usize, 1) << @as(u6, @intCast(diagonal_count));
    var total: usize = 0;
    for (0..limit) |mask| {
        var selected_count: usize = 0;
        for (0..diagonal_count) |i| {
            if ((mask & (@as(usize, 1) << @as(u6, @intCast(i)))) != 0) selected_count += 1;
        }
        if (selected_count != n - 3) continue;
        var crossing = false;
        for (0..diagonal_count) |i| {
            if ((mask & (@as(usize, 1) << @as(u6, @intCast(i)))) == 0) continue;
            for (i + 1..diagonal_count) |j| {
                if ((mask & (@as(usize, 1) << @as(u6, @intCast(j)))) != 0 and
                    properCross(p, diagonal_a[i], diagonal_b[i], diagonal_a[j], diagonal_b[j])) {
                    crossing = true;
                    break;
                }
            }
            if (crossing) break;
        }
        if (crossing) continue;
        var edges = boundary;
        for (0..diagonal_count) |i| {
            if ((mask & (@as(usize, 1) << @as(u6, @intCast(i)))) != 0)
                edges |= edgeBit(diagonal_a[i], diagonal_b[i]);
        }
        var faces: [MAX_TRIANGLES]Triangle = undefined;
        var face_count: usize = 0;
        for (0..n) |a| for (a + 1..n) |b| for (b + 1..n) |c| {
            if (!hasEdge(edges, a, b) or !hasEdge(edges, b, c) or !hasEdge(edges, c, a)) continue;
            const triangle = Triangle{ .a = a, .b = b, .c = c };
            var contains_vertex = false;
            for (0..n) |vertex| {
                if (vertex != a and vertex != b and vertex != c and insideTriangle(p, triangle, vertex)) {
                    contains_vertex = true;
                    break;
                }
            }
            if (!contains_vertex and face_count < MAX_TRIANGLES) {
                faces[face_count] = triangle;
                face_count += 1;
            }
        };
        if (face_count == n - 2 and total < MAX_ALL) {
            output[total] = .{ .triangles = faces, .count = face_count, .edges = edges };
            total += 1;
        }
    }
    return total;
}

fn rankScore(p: [MAX_N]Point, n: usize, target: Fraction) i64 {
    var seen: [MAX_TRIPLES]Fraction = undefined;
    var count: usize = 0;
    for (0..n) |a| for (a + 1..n) |b| for (b + 1..n) |c| {
        const score = triangleScore(p, .{ .a = a, .b = b, .c = c }).score;
        if (compare(score, target) >= 0) continue;
        var duplicate = false;
        for (seen[0..count]) |previous| {
            if (compare(score, previous) == 0) { duplicate = true; break; }
        }
        if (!duplicate) { seen[count] = score; count += 1; }
    };
    return @intCast(count + 1);
}

fn solve(p: [MAX_N]Point, n: usize) i64 {
    var all: [MAX_ALL]Triangulation = undefined;
    const total = enumerate(p, n, &all);
    var fan = Triangulation{ .triangles = undefined, .count = 0, .edges = 0 };
    for (1..n - 1) |middle| {
        fan.triangles[fan.count] = .{ .a = 0, .b = middle, .c = middle + 1 };
        fan.count += 1;
    }
    for (0..n) |a| fan.edges |= edgeBit(a, (a + 1) % n);
    for (2..n - 1) |middle| fan.edges |= edgeBit(0, middle);
    var current_index: ?usize = null;
    for (0..total) |index| if (all[index].edges == fan.edges) { current_index = index; break; };
    if (current_index == null) return -1;
    var current = all[current_index.?];
    var current_metrics = evaluate(p, n, current);
    for (0..MAX_ALL) |_| {
        var changed = false;
        var ti: usize = 0;
        while (ti < current.count and !changed) : (ti += 1) {
            const triangle = current.triangles[ti];
            const scored = triangleScore(p, triangle);
            if (compare(scored.score, current_metrics.maximum) != 0 or scored.score.num == 0) continue;
            var largest: usize = 0;
            for (1..3) |i| if (scored.sides[i] > scored.sides[largest]) { largest = i; };
            const vertices = [_]usize{ triangle.a, triangle.b, triangle.c };
            for (0..3) |anchor_position| {
                if (scored.sides[anchor_position] != scored.sides[largest]) continue;
                const q = vertices[anchor_position];
                var opposite: [2]usize = .{ 0, 0 };
                var used: usize = 0;
                for (0..3) |position| {
                    if (position != anchor_position) { opposite[used] = vertices[position]; used += 1; }
                }
                for (0..n) |s| {
                    const new_edge = edgeBit(q, s);
                    if (s == q or (current.edges & new_edge) != 0 or
                        !properCross(p, q, s, opposite[0], opposite[1])) continue;
                    var retained = current.edges;
                    for (0..n) |u| for (u + 1..n) |v| {
                        const bit = edgeBit(u, v);
                        if ((retained & bit) != 0 and properCross(p, q, s, u, v)) retained &= ~bit;
                    };
                    var selected: ?usize = null;
                    var selected_metrics = Metrics{ .maximum = .{ .num = 0, .den = 1 }, .worst = 0 };
                    for (0..total) |candidate_index| {
                        const candidate = all[candidate_index];
                        if ((candidate.edges & new_edge) == 0 or (candidate.edges & retained) != retained) continue;
                        const candidate_metrics = evaluate(p, n, candidate);
                        if (!improves(candidate_metrics, current_metrics)) continue;
                        if (selected == null or preferable(candidate_metrics, selected_metrics)) {
                            selected = candidate_index;
                            selected_metrics = candidate_metrics;
                        }
                    }
                    if (selected) |chosen| {
                        current = all[chosen];
                        current_metrics = selected_metrics;
                        changed = true;
                        break;
                    }
                }
                if (changed) break;
            }
        }
        if (!changed) break;
    }
    return rankScore(p, n, current_metrics.maximum);
}

export fn convex_polygon_minimax_eccentricity_edge_insertion(input_opt: ?[*]const i64, length: usize) i64 {
    if (input_opt == null or length < 1 or length > MAX_LENGTH) return -1;
    const input = input_opt.?;
    if (input[0] < @as(i64, @intCast(MIN_N)) or input[0] > @as(i64, @intCast(MAX_N))) return -1;
    const n: usize = @intCast(input[0]);
    if (length != 1 + 2 * n) return -1;
    var points: [MAX_N]Point = [_]Point{.{ .x = 0, .y = 0 }} ** MAX_N;
    for (0..n) |i| {
        points[i] = .{ .x = input[1 + 2 * i], .y = input[2 + 2 * i] };
        if (points[i].x < -4 or points[i].x > 4 or points[i].y < -4 or points[i].y > 4) return -1;
        for (0..i) |j| if (points[i].x == points[j].x and points[i].y == points[j].y) return -1;
    }
    var area2: i64 = 0;
    for (0..n) |i| {
        const next = (i + 1) % n;
        area2 += points[i].x * points[next].y - points[i].y * points[next].x;
    }
    if (area2 == 0) return -1;
    const orientation: i64 = if (area2 > 0) 1 else -1;
    for (0..n) |a| for (a + 1..n) |b| for (b + 1..n) |c| {
        if (orient(points, a, b, c) == 0) return -1;
    };
    for (0..n) |edge| {
        const next = (edge + 1) % n;
        for (0..n) |vertex| {
            if (vertex != edge and vertex != next and orientation * orient(points, edge, next, vertex) <= 0) return -1;
        }
    }
    return solve(points, n);
}
