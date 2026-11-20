const MAX_N: usize = 8;
const MAX_M: usize = 20;
const MAX_INPUT: usize = 63;

const Edge = struct { u: i32, v: i32, weight: i32 };

fn graphConnected(n: usize, edges: []const Edge, m: usize, active: u32) bool {
    var seen = [_]bool{false} ** MAX_N;
    var queue = [_]usize{0} ** MAX_N;
    var head: usize = 0;
    var tail: usize = 1;
    seen[0] = true;
    queue[0] = 0;
    while (head < tail) {
        const vertex = queue[head];
        head += 1;
        for (0..m) |id| {
            if (((active >> @intCast(id)) & 1) == 0) continue;
            var neighbor: ?usize = null;
            if (edges[id].u == @as(i32, @intCast(vertex))) neighbor = @intCast(edges[id].v)
            else if (edges[id].v == @as(i32, @intCast(vertex))) neighbor = @intCast(edges[id].u);
            if (neighbor) |other| {
                if (!seen[other]) {
                    seen[other] = true;
                    queue[tail] = other;
                    tail += 1;
                }
            }
        }
    }
    for (0..n) |vertex| {
        if (!seen[vertex]) return false;
    }
    return true;
}

fn storeI64Le(output: [*]u8, offset: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |byte| output[offset + byte] = @truncate(bits >> @intCast(8 * byte));
}

pub export fn reverse_delete_mst(input: ?[*]const i64, length: usize,
    output: ?[*]u8, capacity: usize) i64 {
    if (input == null or length < 2 or length > MAX_INPUT) return -1;
    const values = input.?;
    if (values[0] < 2 or values[0] > MAX_N or values[1] < values[0] - 1 or values[1] > MAX_M) return -1;
    const n: usize = @intCast(values[0]);
    const m: usize = @intCast(values[1]);
    if (length != 2 + 3 * m) return -1;
    var edges: [MAX_M]Edge = undefined;
    var order: [MAX_M]usize = undefined;
    for (0..m) |id| {
        const u = values[2 + 3 * id];
        const v = values[3 + 3 * id];
        const weight = values[4 + 3 * id];
        if (u < 0 or u >= @as(i64, @intCast(n)) or v < 0 or v >= @as(i64, @intCast(n)) or u == v or weight < 0 or weight > 1000) return -1;
        edges[id] = .{ .u = @intCast(u), .v = @intCast(v), .weight = @intCast(weight) };
        order[id] = id;
        const low = @min(u, v);
        const high = @max(u, v);
        for (0..id) |prior| {
            const prior_low = @min(edges[prior].u, edges[prior].v);
            const prior_high = @max(edges[prior].u, edges[prior].v);
            if (low == @as(i64, prior_low) and high == @as(i64, prior_high)) return -1;
        }
    }
    for (1..m) |i| {
        const item = order[i];
        var j = i;
        while (j > 0 and (edges[order[j - 1]].weight < edges[item].weight or
            (edges[order[j - 1]].weight == edges[item].weight and order[j - 1] < item))) {
            order[j] = order[j - 1];
            j -= 1;
        }
        order[j] = item;
    }
    var active: u32 = (@as(u32, 1) << @intCast(m)) - 1;
    if (!graphConnected(n, edges[0..], m, active)) return -1;
    for (0..m) |position| {
        const candidate = active & ~(@as(u32, 1) << @intCast(order[position]));
        if (graphConnected(n, edges[0..], m, candidate)) active = candidate;
    }
    var total_weight: i64 = 0;
    for (0..m) |id| {
        if (((active >> @intCast(id)) & 1) != 0) total_weight += edges[id].weight;
    }
    if (output == null or capacity < 16) return -2;
    storeI64Le(output.?, 0, @intCast(active));
    storeI64Le(output.?, 8, total_weight);
    return 16;
}
