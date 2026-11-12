const std = @import("std");

const MAX_N: usize = 64;
const MAX_Q: usize = 128;
const MAX_LEVEL: usize = 8;
const ROW_SIZE: usize = MAX_N + 1;
const MAX_INPUT_VALUES: usize = 3 * MAX_N + 4 * MAX_Q + 1;
const MAX_ABS_VALUE: i64 = 1_000_000;

const Context = struct {
    n: usize,
    degree: [MAX_N]usize,
    adjacent: [MAX_N][MAX_N]usize,
    removed: [MAX_N]bool,
    parent: [MAX_N]isize,
    subtree_size: [MAX_N]usize,
    ancestor: [MAX_N][MAX_LEVEL]isize,
    distance: [MAX_N][MAX_LEVEL]usize,
    branch_for: [MAX_N][MAX_LEVEL]isize,
    path_length: [MAX_N]usize,
    branch_count: usize,
    total: [MAX_N][ROW_SIZE]i64,
    branch: [MAX_N][ROW_SIZE]i64,
};

fn collectComponent(ctx: *Context, start: usize, order: *[MAX_N]usize) usize {
    var stack: [MAX_N]usize = @splat(0);
    var top: usize = 1;
    var count: usize = 0;
    ctx.parent[start] = -1;
    stack[0] = start;
    while (top > 0) {
        top -= 1;
        const u = stack[top];
        order[count] = u;
        count += 1;
        for (0..ctx.degree[u]) |i| {
            const v = ctx.adjacent[u][i];
            if (ctx.removed[v] or ctx.parent[u] == @as(isize, @intCast(v))) continue;
            ctx.parent[v] = @intCast(u);
            stack[top] = v;
            top += 1;
        }
    }
    var pos = count;
    while (pos > 0) {
        pos -= 1;
        const u = order[pos];
        ctx.subtree_size[u] = 1;
        for (0..ctx.degree[u]) |i| {
            const v = ctx.adjacent[u][i];
            if (!ctx.removed[v] and ctx.parent[v] == @as(isize, @intCast(u)))
                ctx.subtree_size[u] += ctx.subtree_size[v];
        }
    }
    return count;
}

fn decompose(ctx: *Context, start: usize, level: usize) void {
    var order: [MAX_N]usize = @splat(0);
    const count = collectComponent(ctx, start, &order);
    var center = start;
    for (0..count) |i| {
        const u = order[i];
        var largest = count - ctx.subtree_size[u];
        for (0..ctx.degree[u]) |j| {
            const v = ctx.adjacent[u][j];
            if (!ctx.removed[v] and ctx.parent[v] == @as(isize, @intCast(u)))
                largest = @max(largest, ctx.subtree_size[v]);
        }
        if (2 * largest <= count) { center = u; break; }
    }
    ctx.removed[center] = true;
    ctx.ancestor[center][level] = @intCast(center);
    ctx.distance[center][level] = 0;
    ctx.branch_for[center][level] = -1;
    ctx.path_length[center] = level + 1;

    for (0..ctx.degree[center]) |edge| {
        const root = ctx.adjacent[center][edge];
        if (ctx.removed[root]) continue;
        const branch_id = ctx.branch_count;
        ctx.branch_count += 1;
        var nodes: [MAX_N]usize = @splat(0);
        var parents: [MAX_N]usize = @splat(0);
        var distances: [MAX_N]usize = @splat(0);
        var top: usize = 1;
        nodes[0] = root;
        parents[0] = center;
        distances[0] = 1;
        while (top > 0) {
            top -= 1;
            const u = nodes[top];
            const p = parents[top];
            const distance = distances[top];
            ctx.ancestor[u][level] = @intCast(center);
            ctx.distance[u][level] = distance;
            ctx.branch_for[u][level] = @intCast(branch_id);
            ctx.path_length[u] = level + 1;
            for (0..ctx.degree[u]) |j| {
                const v = ctx.adjacent[u][j];
                if (ctx.removed[v] or v == p) continue;
                nodes[top] = v;
                parents[top] = u;
                distances[top] = distance + 1;
                top += 1;
            }
        }
        decompose(ctx, root, level + 1);
    }
}

fn fenwickAdd(row: *[ROW_SIZE]i64, position: usize, delta: i64) void {
    var index = position + 1;
    while (index <= MAX_N) : (index += index & (~index + 1)) row[index] += delta;
}

fn fenwickPrefix(row: *const [ROW_SIZE]i64, count: usize) i64 {
    var total: i64 = 0;
    var index = count;
    while (index > 0) : (index -= index & (~index + 1)) total += row[index];
    return total;
}

fn rowRange(row: *const [ROW_SIZE]i64, left_value: i64, right_value: i64) i64 {
    const left: usize = @intCast(@max(0, @min(@as(i64, MAX_N), left_value)));
    const right: usize = @intCast(@max(0, @min(@as(i64, MAX_N), right_value)));
    if (right <= left) return 0;
    return fenwickPrefix(row, right) - fenwickPrefix(row, left);
}

fn storeI64Le(output: [*c]u8, offset: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |byte| output[offset + byte] = @truncate(bits >> @intCast(byte * 8));
}

export fn vertex_add_range_contour_sum_on_tree(input: [*c]const i64, length: usize,
    output: [*c]u8, capacity: usize) i64 {
    if (input == null or length < 2 or length > MAX_INPUT_VALUES) return -1;
    const packed = input[0..length];
    const n_value = packed[0];
    const q_value = packed[1];
    if (n_value < 1 or n_value > MAX_N or q_value < 0 or q_value > MAX_Q) return -1;
    const n: usize = @intCast(n_value);
    const q: usize = @intCast(q_value);
    if (length < 3 * n) return -1;

    var ctx: Context = std.mem.zeroes(Context);
    ctx.n = n;
    for (0..n) |v| for (0..MAX_LEVEL) |d| {
        ctx.ancestor[v][d] = -1;
        ctx.branch_for[v][d] = -1;
    };
    var values: [MAX_N]i64 = @splat(0);
    for (0..n) |v| {
        values[v] = packed[2 + v];
        if (values[v] < -MAX_ABS_VALUE or values[v] > MAX_ABS_VALUE) return -1;
    }
    const edge_start = 2 + n;
    for (0..n - 1) |i| {
        const u_value = packed[edge_start + 2 * i];
        const v_value = packed[edge_start + 2 * i + 1];
        if (u_value < 0 or u_value >= n_value or v_value < 0 or v_value >= n_value or u_value == v_value) return -1;
        const u: usize = @intCast(u_value);
        const v: usize = @intCast(v_value);
        for (0..ctx.degree[u]) |j| if (ctx.adjacent[u][j] == v) return -1;
        ctx.adjacent[u][ctx.degree[u]] = v;
        ctx.degree[u] += 1;
        ctx.adjacent[v][ctx.degree[v]] = u;
        ctx.degree[v] += 1;
    }
    var seen: [MAX_N]bool = @splat(false);
    var stack: [MAX_N]usize = @splat(0);
    var top: usize = 1;
    var visited: usize = 0;
    stack[0] = 0;
    seen[0] = true;
    while (top > 0) {
        top -= 1;
        const u = stack[top];
        visited += 1;
        for (0..ctx.degree[u]) |i| {
            const v = ctx.adjacent[u][i];
            if (!seen[v]) { seen[v] = true; stack[top] = v; top += 1; }
        }
    }
    if (visited != n) return -1;

    var kinds: [MAX_Q]i64 = @splat(0);
    var vertices: [MAX_Q]usize = @splat(0);
    var first: [MAX_Q]i64 = @splat(0);
    var second: [MAX_Q]i64 = @splat(0);
    var query_count: usize = 0;
    var cursor: usize = 3 * n;
    for (0..q) |i| {
        if (cursor >= length) return -1;
        const kind = packed[cursor];
        cursor += 1;
        if (kind == 0) {
            if (cursor + 2 > length) return -1;
            const p = packed[cursor];
            const delta = packed[cursor + 1];
            cursor += 2;
            if (p < 0 or p >= n_value or delta < -MAX_ABS_VALUE or delta > MAX_ABS_VALUE) return -1;
            kinds[i] = 0; vertices[i] = @intCast(p); first[i] = delta;
        } else if (kind == 1) {
            if (cursor + 3 > length) return -1;
            const p = packed[cursor];
            const left = packed[cursor + 1];
            const right = packed[cursor + 2];
            cursor += 3;
            if (p < 0 or p >= n_value or left < 0 or left >= right or right > n_value) return -1;
            kinds[i] = 1; vertices[i] = @intCast(p); first[i] = left; second[i] = right; query_count += 1;
        } else return -1;
    }
    if (cursor != length) return -1;

    decompose(&ctx, 0, 0);
    for (0..n) |v| for (0..ctx.path_length[v]) |d| {
        const center: usize = @intCast(ctx.ancestor[v][d]);
        const branch_id = ctx.branch_for[v][d];
        fenwickAdd(&ctx.total[center], ctx.distance[v][d], values[v]);
        if (branch_id >= 0) fenwickAdd(&ctx.branch[@intCast(branch_id)], ctx.distance[v][d], values[v]);
    };
    var answers: [MAX_Q]i64 = @splat(0);
    var answer_count: usize = 0;
    for (0..q) |i| {
        const p = vertices[i];
        if (kinds[i] == 0) {
            for (0..ctx.path_length[p]) |d| {
                const center: usize = @intCast(ctx.ancestor[p][d]);
                const branch_id = ctx.branch_for[p][d];
                fenwickAdd(&ctx.total[center], ctx.distance[p][d], first[i]);
                if (branch_id >= 0) fenwickAdd(&ctx.branch[@intCast(branch_id)], ctx.distance[p][d], first[i]);
            }
        } else {
            var total: i64 = 0;
            const left = first[i];
            const right = second[i];
            for (0..ctx.path_length[p]) |d| {
                const center: usize = @intCast(ctx.ancestor[p][d]);
                const branch_id = ctx.branch_for[p][d];
                const shifted_left = left - @as(i64, @intCast(ctx.distance[p][d]));
                const shifted_right = right - @as(i64, @intCast(ctx.distance[p][d]));
                total += rowRange(&ctx.total[center], shifted_left, shifted_right);
                if (branch_id >= 0) total -= rowRange(&ctx.branch[@intCast(branch_id)], shifted_left, shifted_right);
            }
            answers[answer_count] = total;
            answer_count += 1;
        }
    }
    const output_bytes = answer_count * 8;
    if (output_bytes > 0 and (output == null or capacity < output_bytes)) return -2;
    for (0..answer_count) |i| storeI64Le(output, i * 8, answers[i]);
    return @intCast(output_bytes);
}
