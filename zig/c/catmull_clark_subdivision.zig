const std = @import("std");

const MAX_V: usize = 24;
const MAX_F: usize = 8;
const MAX_D: usize = 8;
const MAX_E: usize = 32;
const MAX_IN: usize = 122;
const MAX_OUT: usize = 386;

const Edge = struct { u: usize, v: usize, f0: usize, f1: usize, uses: usize };

fn integer(value: f64, low: usize, high: usize) ?usize {
    if (!std.math.isFinite(value) or @trunc(value) != value or value < @as(f64, @floatFromInt(low)) or
        value > @as(f64, @floatFromInt(high))) return null;
    return @intFromFloat(value);
}
fn mean(values: []const f64) f64 {
    var scale: f64 = 0.0;
    for (values) |value| scale = @max(scale, @abs(value));
    if (scale == 0.0) return 0.0;
    var sum: f64 = 0.0;
    for (values) |value| sum += value / scale;
    return (sum / @as(f64, @floatFromInt(values.len))) * scale;
}
fn average4(a: f64, b: f64, c: f64, d: f64) f64 {
    const scale = @max(@max(@abs(a), @abs(b)), @max(@abs(c), @abs(d)));
    if (scale == 0.0) return 0.0;
    return ((a/scale+b/scale+c/scale+d/scale)*0.25)*scale;
}

export fn catmull_clark_subdivision(input_opt: ?[*]const f64, length: usize,
        output_opt: ?[*]f64, capacity: usize) i64 {
    const input = input_opt orelse return -1;
    if (length < 2 or length > MAX_IN) return -1;
    for (input[0..length]) |value| if (!std.math.isFinite(value)) { return -1; };
    const nv = integer(input[0], 0, MAX_V) orelse return -1;
    const nf = integer(input[1], 0, MAX_F) orelse return -1;
    if ((nv == 0 or nf == 0) and !(nv == 0 and nf == 0 and length == 2)) return -1;

    var x = [_]f64{0} ** MAX_V;
    var y = [_]f64{0} ** MAX_V;
    var degree = [_]usize{0} ** MAX_F;
    var face = [_][MAX_D]usize{[_]usize{0} ** MAX_D} ** MAX_F;
    var pos: usize = 2;
    if (pos + 2 * nv > length) return -1;
    for (0..nv) |v| { x[v] = input[pos]; y[v] = input[pos + 1]; pos += 2; }

    var edges = [_]Edge{.{ .u = 0, .v = 0, .f0 = 0, .f1 = 0, .uses = 0 }} ** MAX_E;
    var edge_count: usize = 0;
    for (0..nf) |f| {
        if (pos >= length) return -1;
        degree[f] = integer(input[pos], 3, MAX_D) orelse return -1;
        pos += 1;
        if (pos + degree[f] > length) return -1;
        for (0..degree[f]) |i| {
            face[f][i] = integer(input[pos], 0, nv -| 1) orelse return -1;
            if (nv == 0) return -1;
            pos += 1;
            for (0..i) |j| if (face[f][i] == face[f][j]) { return -1; };
        }
        for (0..degree[f]) |i| {
            const a = face[f][i]; const b = face[f][(i + 1) % degree[f]];
            const u = @min(a, b); const v = @max(a, b);
            var found: ?usize = null;
            for (0..edge_count) |e| if (edges[e].u == u and edges[e].v == v) { found = e; break; };
            if (found) |e| {
                if (edges[e].uses != 1 or edges[e].f0 == f) return -1;
                edges[e].uses = 2; edges[e].f1 = f;
            } else {
                if (edge_count == MAX_E) return -1;
                edges[edge_count] = .{ .u = u, .v = v, .f0 = f, .f1 = 0, .uses = 1 };
                edge_count += 1;
            }
        }
    }
    if (pos != length) return -1;
    for (0..edge_count) |e| if (edges[e].uses != 2) { return -1; };

    for (0..nv) |vertex| {
        var valence: usize = 0;
        for (0..edge_count) |e| if (edges[e].u == vertex or edges[e].v == vertex) { valence += 1; };
        var link_a = [_]usize{0} ** MAX_F;
        var link_b = [_]usize{0} ** MAX_F;
        var links: usize = 0;
        for (0..nf) |f| for (0..degree[f]) |i| {
            if (face[f][i] == vertex) {
                const a = face[f][(i + degree[f] - 1) % degree[f]];
                const b = face[f][(i + 1) % degree[f]];
                const lo = @min(a, b); const hi = @max(a, b);
                for (0..links) |j| if (@min(link_a[j], link_b[j]) == lo and @max(link_a[j], link_b[j]) == hi) { return -1; };
                link_a[links] = a; link_b[links] = b; links += 1;
            }
        };
        if (valence < 3 or links != valence) return -1;
        var reached = [_]bool{false} ** MAX_V;
        reached[link_a[0]] = true;
        var changed = true;
        while (changed) {
            changed = false;
            for (0..links) |i| {
                if (reached[link_a[i]] and !reached[link_b[i]]) { reached[link_b[i]] = true; changed = true; }
                if (reached[link_b[i]] and !reached[link_a[i]]) { reached[link_a[i]] = true; changed = true; }
            }
        }
        var node_degree = [_]usize{0} ** MAX_V;
        for (0..links) |i| { node_degree[link_a[i]] += 1; node_degree[link_b[i]] += 1; }
        var nodes: usize = 0;
        for (0..nv) |u| if (node_degree[u] != 0) { nodes += 1; if (node_degree[u] != 2 or !reached[u]) return -1; };
        if (nodes < 3) return -1;
    }

    for (1..edge_count) |i| {
        const item = edges[i];
        var j = i;
        while (j > 0 and (edges[j - 1].u > item.u or (edges[j - 1].u == item.u and edges[j - 1].v > item.v))) {
            edges[j] = edges[j - 1]; j -= 1;
        }
        edges[j] = item;
    }
    var face_x = [_]f64{0} ** MAX_F;
    var face_y = [_]f64{0} ** MAX_F;
    for (0..nf) |f| {
        var vx = [_]f64{0} ** MAX_D; var vy = [_]f64{0} ** MAX_D;
        for (0..degree[f]) |i| { vx[i] = x[face[f][i]]; vy[i] = y[face[f][i]]; }
        face_x[f] = mean(vx[0..degree[f]]); face_y[f] = mean(vy[0..degree[f]]);
    }

    var staged = [_]f64{0} ** MAX_OUT;
    var out: usize = 0;
    const new_vertices = nv + edge_count + nf;
    var new_faces: usize = 0;
    for (0..nf) |f| new_faces += degree[f];
    staged[out] = @floatFromInt(new_vertices); out += 1;
    staged[out] = @floatFromInt(new_faces); out += 1;
    for (0..nv) |vertex| {
        var fxs = [_]f64{0} ** MAX_F; var fys = [_]f64{0} ** MAX_F;
        var rx = [_]f64{0} ** MAX_F; var ry = [_]f64{0} ** MAX_F;
        var nfi: usize = 0; var nei: usize = 0;
        for (0..nf) |f| {
            for (0..degree[f]) |i| if (face[f][i] == vertex) { fxs[nfi] = face_x[f]; fys[nfi] = face_y[f]; nfi += 1; break; };
        }
        for (0..edge_count) |e| if (edges[e].u == vertex or edges[e].v == vertex) {
            rx[nei] = mean(&.{x[edges[e].u], x[edges[e].v]});
            ry[nei] = mean(&.{y[edges[e].u], y[edges[e].v]});
            nei += 1;
        };
        const fxa = mean(fxs[0..nfi]); const fya = mean(fys[0..nfi]);
        const rxa = mean(rx[0..nei]); const rya = mean(ry[0..nei]);
        const sx = @max(@abs(x[vertex]), @max(@abs(fxa), @abs(rxa)));
        const sy = @max(@abs(y[vertex]), @max(@abs(fya), @abs(rya)));
        staged[out] = if (sx == 0.0) 0.0 else ((fxa/sx + 2.0*rxa/sx + (@as(f64,@floatFromInt(nei))-3.0)*(x[vertex]/sx)) / @as(f64,@floatFromInt(nei))) * sx; out += 1;
        staged[out] = if (sy == 0.0) 0.0 else ((fya/sy + 2.0*rya/sy + (@as(f64,@floatFromInt(nei))-3.0)*(y[vertex]/sy)) / @as(f64,@floatFromInt(nei))) * sy; out += 1;
    }
    for (0..edge_count) |e| {
        staged[out] = average4(x[edges[e].u], x[edges[e].v], face_x[edges[e].f0], face_x[edges[e].f1]); out += 1;
        staged[out] = average4(y[edges[e].u], y[edges[e].v], face_y[edges[e].f0], face_y[edges[e].f1]); out += 1;
    }
    for (0..nf) |f| { staged[out] = face_x[f]; out += 1; staged[out] = face_y[f]; out += 1; }
    for (0..nf) |f| for (0..degree[f]) |i| {
        const vertex = face[f][i]; const next = face[f][(i+1)%degree[f]]; const prev = face[f][(i+degree[f]-1)%degree[f]];
        const next_edge = @min(vertex,next); const next_high = @max(vertex,next);
        const prev_edge = @min(prev,vertex); const prev_high = @max(prev,vertex);
        var en: usize = 0; var ep: usize = 0;
        for (0..edge_count) |e| { if(edges[e].u==next_edge and edges[e].v==next_high)en=e;if(edges[e].u==prev_edge and edges[e].v==prev_high)ep=e; }
        staged[out]=@floatFromInt(vertex);out+=1;staged[out]=@floatFromInt(nv+en);out+=1;staged[out]=@floatFromInt(nv+edge_count+f);out+=1;staged[out]=@floatFromInt(nv+ep);out+=1;
    };
    if (out > MAX_OUT) return -1;
    if (output_opt == null or capacity < out) return -2;
    const output = output_opt.?;
    @memcpy(output[0..out], staged[0..out]);
    return @intCast(out);
}
