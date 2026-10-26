// Clean-room bounded GARDENIA Forward-Backward-Trim SCC profile.
const MAX_N = 16;
const MAX_M = 64;
const MAX_INPUT = 130;
const MAX_TASKS = 34;

fn reach(active: u32, pivot: usize, adjacency: [MAX_N * MAX_N]u8,
         reverse: bool, n: usize) u32 {
    var seen = @as(u32, 1) << @intCast(pivot);
    while (true) {
        var expanded = seen;
        for (0..n) |u| {
            const ub = @as(u32, 1) << @intCast(u);
            if ((seen & ub) == 0 or (active & ub) == 0) continue;
            for (0..n) |v| {
                const vb = @as(u32, 1) << @intCast(v);
                const edge = if (reverse) adjacency[v * MAX_N + u] != 0 else adjacency[u * MAX_N + v] != 0;
                if ((active & vb) != 0 and edge) expanded |= vb;
            }
        }
        if (expanded == seen) return seen;
        seen = expanded;
    }
}

fn putI64Le(output: [*]u8, offset: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |byte| output[offset + byte] = @truncate(bits >> @intCast(8 * byte));
}

export fn gardenia_fb_trim_scc(input_opt: ?[*]const i64, length: usize,
    output_opt: ?[*]u8, capacity: usize) i64 {
    if (input_opt == null or length < 2 or length > MAX_INPUT) return -1;
    const input = input_opt.?;
    const n64, const m64 = .{ input[0], input[1] };
    if (n64 < 1 or n64 > MAX_N or m64 < 0 or m64 > MAX_M or length != 2 + 2 * @as(usize, @intCast(m64))) return -1;
    const n: usize = @intCast(n64);
    const m: usize = @intCast(m64);
    var adjacency: [MAX_N * MAX_N]u8 = @splat(0);
    for (0..m) |e| {
        const u64 = input[2 + 2 * e];
        const v64 = input[3 + 2 * e];
        if (u64 < 0 or u64 >= n64 or v64 < 0 or v64 >= n64) return -1;
        const u: usize = @intCast(u64);
        const v: usize = @intCast(v64);
        if (adjacency[u * MAX_N + v] != 0) return -1;
        adjacency[u * MAX_N + v] = 1;
    }
    const output_bytes = 8 * n;
    if (output_opt == null or capacity < output_bytes) return -2;
    var labels: [MAX_N]i64 = @splat(0);
    var tasks: [MAX_TASKS]u32 = @splat(0);
    var task_count: usize = 1;
    tasks[0] = (@as(u32, 1) << @intCast(n)) - 1;
    while (task_count > 0) {
        task_count -= 1;
        var active = tasks[task_count];
        while (active != 0) {
            var trimmed: u32 = 0;
            for (0..n) |u| {
                const ub = @as(u32, 1) << @intCast(u);
                if ((active & ub) == 0) continue;
                var has_in = false;
                var has_out = false;
                for (0..n) |v| {
                    const vb = @as(u32, 1) << @intCast(v);
                    if ((active & vb) == 0) continue;
                    has_out = has_out or adjacency[u * MAX_N + v] != 0;
                    has_in = has_in or adjacency[v * MAX_N + u] != 0;
                }
                if (!has_in or !has_out) trimmed |= ub;
            }
            if (trimmed == 0) break;
            for (0..n) |u| if ((trimmed & (@as(u32, 1) << @intCast(u))) != 0) { labels[u] = @intCast(u); };
            active &= ~trimmed;
        }
        if (active == 0) continue;
        var pivot: usize = 0;
        while ((active & (@as(u32, 1) << @intCast(pivot))) == 0) : (pivot += 1) {}
        const forward = reach(active, pivot, adjacency, false, n);
        const backward = reach(active, pivot, adjacency, true, n);
        const component = forward & backward;
        var representative: usize = 0;
        while ((component & (@as(u32, 1) << @intCast(representative))) == 0) : (representative += 1) {}
        for (0..n) |u| if ((component & (@as(u32, 1) << @intCast(u))) != 0) { labels[u] = @intCast(representative); };
        const children = [_]u32{ active & ~(forward | backward), forward & ~backward, backward & ~forward };
        for (children) |child| {
            if (child != 0) {
                if (task_count >= MAX_TASKS) return -1;
                tasks[task_count] = child;
                task_count += 1;
            }
        }
    }
    const output = output_opt.?;
    for (0..n) |u| putI64Le(output, 8 * u, labels[u]);
    return @intCast(output_bytes);
}
