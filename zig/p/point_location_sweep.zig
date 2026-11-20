const Point = struct { x: i64, y: i64 };
const Edge = struct { u: usize, v: usize, face: i64 };
const Event = struct { x: i64, kind: i64, id: usize };
const MAX_N: usize = 16;
const MAX_M: usize = 24;
const MAX_Q: usize = 16;
const MAX_EVENTS: usize = 64;

fn orient(a: Point, b: Point, c: Point) i64 {
    return (b.x - a.x) * (c.y - a.y) - (b.y - a.y) * (c.x - a.x);
}
fn between(x: i64, a: i64, b: i64) bool { return x >= @min(a, b) and x <= @max(a, b); }
fn onSegment(a: Point, b: Point, p: Point) bool {
    return orient(a, b, p) == 0 and between(p.x, a.x, b.x) and between(p.y, a.y, b.y);
}
fn intersects(a: Point, b: Point, c: Point, d: Point) bool {
    const o1 = orient(a, b, c); const o2 = orient(a, b, d);
    const o3 = orient(c, d, a); const o4 = orient(c, d, b);
    if ((o1 == 0 and onSegment(a,b,c)) or (o2 == 0 and onSegment(a,b,d)) or
        (o3 == 0 and onSegment(c,d,a)) or (o4 == 0 and onSegment(c,d,b))) return true;
    return ((o1 < 0 and o2 > 0) or (o1 > 0 and o2 < 0)) and
        ((o3 < 0 and o4 > 0) or (o3 > 0 and o4 < 0));
}
fn endpoints(points: []const Point, edges: []const Edge, e: usize) struct { l: Point, r: Point } {
    const a = points[edges[e].u]; const b = points[edges[e].v];
    return if (a.x < b.x) .{ .l = a, .r = b } else .{ .l = b, .r = a };
}
fn height(points: []const Point, edges: []const Edge, e: usize, x: i64) struct { num: i64, den: i64 } {
    const ends = endpoints(points, edges, e); const d = ends.r.x - ends.l.x;
    return .{ .num = ends.l.y * d + (ends.r.y - ends.l.y) * (x - ends.l.x), .den = d };
}
fn edgeLess(points: []const Point, edges: []const Edge, a: usize, b: usize, x: i64) bool {
    const ha = height(points, edges, a, x); const hb = height(points, edges, b, x);
    if (ha.num * hb.den != hb.num * ha.den) return ha.num * hb.den < hb.num * ha.den;
    const ea = endpoints(points, edges, a); const eb = endpoints(points, edges, b);
    const sa = (ea.r.y - ea.l.y) * (eb.r.x - eb.l.x);
    const sb = (eb.r.y - eb.l.y) * (ea.r.x - ea.l.x);
    return if (sa != sb) sa < sb else a < b;
}
fn eventLess(a: Event, b: Event) bool {
    if (a.x != b.x) return a.x < b.x;
    if (a.kind != b.kind) return a.kind < b.kind;
    return a.id < b.id;
}

export fn point_location_sweep(values: [*c]const i64, length: usize) i64 {
    if (values == null or length < 4 or length > 141) return -1;
    const n_raw = values[0]; const m_raw = values[1]; const q_raw = values[2]; const f = values[3];
    if (n_raw < 2 or n_raw > 16 or m_raw < 1 or m_raw > 24 or q_raw < 0 or q_raw > 16 or f < 1 or f > 16) return -1;
    const n: usize = @intCast(n_raw); const m: usize = @intCast(m_raw); const q: usize = @intCast(q_raw);
    if (length != 4 + 2*n + 3*m + 2*q) return -1;
    var points_buf: [MAX_N]Point = undefined; const points = points_buf[0..n];
    var edges_buf: [MAX_M]Edge = undefined; const edges = edges_buf[0..m];
    var qx: [MAX_Q]i64 = undefined; var qy: [MAX_Q]i64 = undefined;
    var pos: usize = 4;
    for (0..n) |i| {
        points[i] = .{ .x = values[pos], .y = values[pos+1] }; pos += 2;
        if (points[i].x < -300 or points[i].x > 300 or points[i].y < -300 or points[i].y > 300) return -1;
        for (0..i) |j| if (points[i].x == points[j].x) { return -1; };
    }
    for (0..m) |i| {
        const ur = values[pos]; const vr = values[pos+1]; const face = values[pos+2]; pos += 3;
        if (ur < 0 or ur >= n_raw or vr < 0 or vr >= n_raw or ur == vr or face < -1 or face >= f) return -1;
        edges[i] = .{ .u = @intCast(ur), .v = @intCast(vr), .face = face };
        for (0..i) |j| {
            const e = edges[i]; const g = edges[j];
            if ((e.u == g.u and e.v == g.v) or (e.u == g.v and e.v == g.u)) return -1;
        }
    }
    for (0..m) |i| for (0..i) |j| {
        const e = edges[i]; const g = edges[j]; var shared: ?usize = null;
        if (e.u == g.u or e.u == g.v) shared = e.u else if (e.v == g.u or e.v == g.v) shared = e.v;
        if (shared) |s| {
            const oi = if (e.u == s) e.v else e.u; const oj = if (g.u == s) g.v else g.u;
            if (orient(points[s], points[oi], points[oj]) == 0) return -1;
        } else if (intersects(points[e.u], points[e.v], points[g.u], points[g.v])) return -1;
    };
    for (0..q) |i| {
        qx[i] = values[pos]; qy[i] = values[pos+1]; pos += 2;
        if (qx[i] < -300 or qx[i] > 300 or qy[i] < -300 or qy[i] > 300) return -1;
        for (points) |p| if (qx[i] == p.x) { return -1; };
    }
    var events_buf: [MAX_EVENTS]Event = undefined; var ec: usize = 0;
    for (0..m) |i| { const ends = endpoints(points, edges, i); events_buf[ec] = .{ .x=ends.l.x, .kind=1, .id=i }; ec += 1; events_buf[ec] = .{ .x=ends.r.x, .kind=0, .id=i }; ec += 1; }
    for (0..q) |i| { events_buf[ec] = .{ .x=qx[i], .kind=2, .id=i }; ec += 1; }
    const events = events_buf[0..ec];
    for (1..ec) |i| { const key = events[i]; var j = i; while (j > 0 and eventLess(key, events[j-1])) : (j -= 1) { events[j] = events[j-1]; } events[j] = key; }
    var active: [MAX_M]usize = undefined; var ac: usize = 0; var response: [MAX_Q]i64 = [_]i64{0} ** MAX_Q;
    for (events) |ev| {
        if (ev.kind == 0) {
            var k: usize = 0; while (k < ac and active[k] != ev.id) : (k += 1) {}
            if (k == ac) return -1; while (k + 1 < ac) : (k += 1) { active[k] = active[k+1]; } ac -= 1;
        } else if (ev.kind == 1) {
            var k: usize = 0; while (k < ac and edgeLess(points, edges, active[k], ev.id, ev.x)) : (k += 1) {}
            var h = ac; while (h > k) : (h -= 1) { active[h] = active[h-1]; } active[k] = ev.id; ac += 1;
        } else {
            var lo: usize = 0; var hi = ac;
            while (lo < hi) { const mid = (lo+hi)/2; const h = height(points, edges, active[mid], ev.x); if (h.num < qy[ev.id]*h.den) lo = mid+1 else hi=mid; }
            if (lo < ac) { const h=height(points,edges,active[lo],ev.x); if (h.num==qy[ev.id]*h.den) response[ev.id]=f+@as(i64,@intCast(active[lo]))+1 else if (lo>0 and edges[active[lo-1]].face>=0) response[ev.id]=edges[active[lo-1]].face+1; }
            else if (lo>0 and edges[active[lo-1]].face>=0) response[ev.id]=edges[active[lo-1]].face+1;
        }
    }
    var result: i64 = 0; for (0..q) |i| result += @as(i64,@intCast(i+1))*response[i]; return result;
}
