// Clean-room bounded GOC-MCDS-C construction trace.
const MAX_N: usize = 8;
const MAX_INPUT: usize = 17;

fn put64(output: [*]u8, position: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |byte| output[position + byte] = @truncate(bits >> @intCast(8 * byte));
}

export fn routing_cost_constrained_cds_goc_mcds_c(input_opt: ?[*]const i64, length: usize,
    output_opt: ?[*]u8, capacity: usize) i64 {
    if (input_opt == null or length < 3 or length > MAX_INPUT) return -1;
    const input = input_opt.?;
    if (input[0] < 1 or input[0] > 8) return -1;
    const n: usize = @intCast(input[0]);
    if (length != 1 + 2 * n) return -1;
    const full = (@as(u64, 1) << @intCast(n)) - 1;
    var adjacency: [MAX_N]u64 = @splat(0);
    var ids: [MAX_N]i64 = @splat(0);
    for (0..n) |v| {
        const mask = input[1 + v]; ids[v] = input[1 + n + v];
        if (mask < 0 or @as(u64, @intCast(mask)) > full or ((@as(u64, @intCast(mask)) >> @intCast(v)) & 1) != 0 or ids[v] < 1 or ids[v] > 1000) return -1;
        adjacency[v] = @intCast(mask);
        for (0..v) |u| { if (ids[u] == ids[v]) return -1; }
    }
    for (0..n) |u| for (0..n) |v| {
        if (((adjacency[u] >> @intCast(v)) & 1) != ((adjacency[v] >> @intCast(u)) & 1)) return -1;
    };
    var reached: u64 = 1;
    while (true) {
        var expanded = reached;
        for (0..n) |v| { if (((reached >> @intCast(v)) & 1) != 0) expanded |= adjacency[v]; }
        if (expanded == reached) break;
        reached = expanded;
    }
    if (reached != full) return -1;

    var white = full;
    var independent: u64 = 0;
    while (white != 0) {
        var black: u64 = 0;
        for (0..n) |v| {
            if (((white >> @intCast(v)) & 1) == 0) continue;
            var lower = false;
            for (0..n) |u| {
                if (((white >> @intCast(u)) & 1) != 0 and ((adjacency[v] >> @intCast(u)) & 1) != 0 and ids[u] < ids[v]) lower = true;
            }
            if (!lower) black |= @as(u64, 1) << @intCast(v);
        }
        if (black == 0) return -1;
        independent |= black;
        var removed = black;
        for (0..n) |v| { if (((black >> @intCast(v)) & 1) != 0) removed |= adjacency[v]; }
        white &= ~removed;
    }
    var order: [MAX_N]usize = @splat(0);
    for (0..n) |i| order[i] = i;
    std.mem.sort(usize, order[0..n], ids[0..n], struct {
        fn less(context: []const i64, a: usize, b: usize) bool { return context[a] < context[b]; }
    }.less);
    var connectors: u64 = 0;
    for (0..n) |a| {
        const source = order[a];
        if (((independent >> @intCast(source)) & 1) == 0) continue;
        var b = a + 1;
        while (b < n) : (b += 1) {
            const target = order[b];
            if (((independent >> @intCast(target)) & 1) == 0) continue;
            var parent: [MAX_N]i8 = @splat(-2);
            var queue: [MAX_N]usize = @splat(0);
            var head: usize = 0;
            var tail: usize = 1;
            parent[source] = -1; queue[0] = source;
            while (head < tail and parent[target] == -2) {
                const current = queue[head]; head += 1;
                for (0..n) |oi| {
                    const next = order[oi];
                    if (((adjacency[current] >> @intCast(next)) & 1) != 0 and parent[next] == -2) {
                        parent[next] = @intCast(current); queue[tail] = next; tail += 1;
                    }
                }
            }
            if (parent[target] == -2) return -1;
            var path: [MAX_N]usize = @splat(0);
            var path_length: usize = 0;
            var current = target;
            while (current != source) { path[path_length] = current; path_length += 1; current = @intCast(parent[current]); }
            path[path_length] = source; path_length += 1;
            if (path_length <= 4) for (1..path_length - 1) |i| connectors |= @as(u64, 1) << @intCast(path[i]);
        }
    }
    if (output_opt == null or capacity < 16) return -2;
    var staged: [16]u8 = @splat(0);
    put64(&staged, 0, @intCast(independent));
    put64(&staged, 8, @intCast(independent | connectors));
    const output = output_opt.?;
    @memcpy(output[0..16], staged[0..16]);
    return 16;
}

const std = @import("std");
