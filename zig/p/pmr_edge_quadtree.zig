const MAX_SEGMENTS: usize = 8;
const MAX_DEPTH: usize = 8;
const MAX_NODES: usize = 2048;
const MAX_INPUT: usize = 35;

const Node = struct {
    parent: i64 = -1,
    quadrant: i64 = -1,
    depth: i64 = 0,
    bounds: [4]i64 = @splat(0),
    children: [4]i64 = @splat(-1),
    ids: [MAX_SEGMENTS]i64 = @splat(0),
    id_count: usize = 0,
};
const State = struct {
    nodes: [MAX_NODES]Node = @splat(.{}),
    used: usize = 1,
    segments: [MAX_SEGMENTS][4]i64 = @splat(@splat(0)),
};

fn orient(a: [2]i64, b: [2]i64, c: [2]i64) i64 {
    return (b[0] - a[0]) * (c[1] - a[1]) - (b[1] - a[1]) * (c[0] - a[0]);
}
fn between(a: i64, b: i64, p: i64) bool { return (a <= p and p <= b) or (b <= p and p <= a); }
fn onSegment(a: [2]i64, b: [2]i64, p: [2]i64) bool {
    return between(a[0], b[0], p[0]) and between(a[1], b[1], p[1]);
}
fn intersects(a: [2]i64, b: [2]i64, c: [2]i64, d: [2]i64) bool {
    const o1 = orient(a, b, c); const o2 = orient(a, b, d);
    const o3 = orient(c, d, a); const o4 = orient(c, d, b);
    return (((o1 < 0 and o2 > 0) or (o1 > 0 and o2 < 0)) and
        ((o3 < 0 and o4 > 0) or (o3 > 0 and o4 < 0))) or
        (o1 == 0 and onSegment(a,b,c)) or (o2 == 0 and onSegment(a,b,d)) or
        (o3 == 0 and onSegment(c,d,a)) or (o4 == 0 and onSegment(c,d,b));
}
fn intersectsBox(state: *const State, sid: usize, bounds: [4]i64) bool {
    const s = state.segments[sid];
    const a = [2]i64{2*s[0], 2*s[1]}; const b = [2]i64{2*s[2], 2*s[3]};
    const lx = bounds[0]; const ly = bounds[1]; const hx = bounds[2]; const hy = bounds[3];
    const inside_a = lx <= a[0] and a[0] <= hx and ly <= a[1] and a[1] <= hy;
    const inside_b = lx <= b[0] and b[0] <= hx and ly <= b[1] and b[1] <= hy;
    if (inside_a or inside_b) return true;
    return intersects(a,b,.{lx,ly},.{hx,ly}) or intersects(a,b,.{hx,ly},.{hx,hy}) or
        intersects(a,b,.{hx,hy},.{lx,hy}) or intersects(a,b,.{lx,hy},.{lx,ly});
}
fn setNode(state: *State, id: usize, parent: i64, quadrant: i64, depth: i64, bounds: [4]i64) void {
    state.nodes[id] = .{.parent=parent,.quadrant=quadrant,.depth=depth,.bounds=bounds};
}
fn insert(state: *State, node_id: usize, sid: usize, threshold: usize) bool {
    if (state.nodes[node_id].children[0] >= 0) {
        for (0..4) |q| {
            const child: usize = @intCast(state.nodes[node_id].children[q]);
            if (intersectsBox(state, sid, state.nodes[child].bounds) and !insert(state, child, sid, threshold)) return false;
        }
        return true;
    }
    if (state.nodes[node_id].id_count >= MAX_SEGMENTS) return false;
    const slot = state.nodes[node_id].id_count;
    state.nodes[node_id].ids[slot] = @intCast(sid);
    state.nodes[node_id].id_count += 1;
    if (state.nodes[node_id].id_count <= threshold) return true;
    if (state.nodes[node_id].depth >= MAX_DEPTH or state.used + 4 > MAX_NODES) return false;

    const previous = state.nodes[node_id].ids;
    const previous_count = state.nodes[node_id].id_count;
    const bounds = state.nodes[node_id].bounds;
    const mx = bounds[0] + (bounds[2] - bounds[0]) / 2;
    const my = bounds[1] + (bounds[3] - bounds[1]) / 2;
    const base = state.used;
    for (0..4) |q| {
        const x0 = if (q % 2 == 0) bounds[0] else mx;
        const x1 = if (q % 2 == 0) mx else bounds[2];
        const y0 = if (q < 2) my else bounds[1];
        const y1 = if (q < 2) bounds[3] else my;
        setNode(state, base + q, @intCast(node_id), @intCast(q), state.nodes[node_id].depth + 1, .{x0,y0,x1,y1});
    }
    state.used += 4;
    state.nodes[node_id].children = .{@intCast(base),@intCast(base+1),@intCast(base+2),@intCast(base+3)};
    state.nodes[node_id].id_count = 0;
    for (0..previous_count) |i| {
        const old_sid: usize = @intCast(previous[i]);
        for (0..4) |q| {
            const child = base + q;
            if (intersectsBox(state, old_sid, state.nodes[child].bounds) and !insert(state, child, old_sid, threshold)) return false;
        }
    }
    return true;
}
fn walk(state: *const State, id: usize, order: *[MAX_NODES]usize, used: *usize) void {
    order[used.*] = id; used.* += 1;
    if (state.nodes[id].children[0] >= 0) for (state.nodes[id].children) |child| walk(state, @intCast(child), order, used);
}
fn storeLe(output: []u8, offset: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |byte| output[offset + byte] = @truncate(bits >> @intCast(byte * 8));
}
fn solve(input: []const i64, output_opt: ?[]u8) i64 {
    if (input.len < 2 or input.len > MAX_INPUT or input[0] < 0 or input[0] > 8 or input[1] < 1 or input[1] > 8) return -1;
    const count: usize = @intCast(input[0]); const threshold: usize = @intCast(input[1]);
    if (input.len != 2 + 4 * count) return -1;
    var state = State{};
    for (0..count) |sid| {
        for (0..4) |k| {
            const value = input[2 + sid * 4 + k];
            if (value < 0 or value > 255) return -1;
            state.segments[sid][k] = value;
        }
        if (state.segments[sid][0] == state.segments[sid][2] and state.segments[sid][1] == state.segments[sid][3]) return -1;
    }
    setNode(&state, 0, -1, -1, 0, .{-1,-1,511,511});
    for (0..count) |sid| if (!insert(&state, 0, sid, threshold)) return -1;
    var order: [MAX_NODES]usize = @splat(0); var remap: [MAX_NODES]i64 = @splat(0); var node_count: usize = 0;
    walk(&state, 0, &order, &node_count);
    var bytes: usize = 16;
    for (order[0..node_count]) |id| bytes += 32 + 8 * state.nodes[id].id_count;
    if (output_opt == null or output_opt.?.len < bytes) return -2;
    const output = output_opt.?;
    for (0..node_count) |i| remap[order[i]] = @intCast(i);
    storeLe(output, 0, @intCast(node_count)); storeLe(output, 8, @intCast(count));
    var cursor: usize = 16;
    for (0..node_count) |i| {
        const node = state.nodes[order[i]];
        storeLe(output,cursor,if (node.parent < 0) -1 else remap[@intCast(node.parent)]); cursor += 8;
        storeLe(output,cursor,node.quadrant); cursor += 8;
        storeLe(output,cursor,node.depth); cursor += 8;
        storeLe(output,cursor,@intCast(node.id_count)); cursor += 8;
        for (node.ids[0..node.id_count]) |sid| { storeLe(output,cursor,sid); cursor += 8; }
    }
    return @intCast(bytes);
}
export fn pmr_edge_quadtree(input: [*c]const i64, length: usize, output: [*c]u8, capacity: usize) i64 {
    if (input == null or length < 2 or length > MAX_INPUT) return -1;
    const values = input[0..length];
    if (output == null) return solve(values, null);
    return solve(values, output[0..capacity]);
}
