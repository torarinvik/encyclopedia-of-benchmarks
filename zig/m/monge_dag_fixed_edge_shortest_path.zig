const MaxN: usize = 32;
const Side: usize = 33;
const MaxInput: usize = 531;
const Inf: i64 = 1152921504606846976;

const Frame = struct { row_begin: usize, row_end: usize, col_begin: usize, col_end: usize };

fn mongeLayer(n: usize, layer: usize, dp: *const [Side]i64,
    cost: *const [Side * Side]i64, next: *[Side]i64) void {
    var stack: [64]Frame = undefined;
    var top: usize = 1;
    stack[0] = .{ .row_begin = layer, .row_end = n + 1, .col_begin = layer - 1, .col_end = n };
    while (top > 0) {
        top -= 1;
        const frame = stack[top];
        if (frame.row_begin >= frame.row_end) continue;
        const row = (frame.row_begin + frame.row_end) / 2;
        const upper = @min(frame.col_end, row);
        var best_column = frame.col_begin;
        var best_value = Inf;
        for (frame.col_begin..upper) |column| {
            if (dp[column] == Inf) continue;
            const candidate = dp[column] + cost[column * Side + row];
            if (candidate < best_value) { best_value = candidate; best_column = column; }
        }
        next[row] = best_value;
        if (row + 1 < frame.row_end and best_column < frame.col_end) {
            stack[top] = .{ .row_begin = row + 1, .row_end = frame.row_end,
                .col_begin = best_column, .col_end = frame.col_end };
            top += 1;
        }
        if (frame.row_begin < row and frame.col_begin <= best_column) {
            stack[top] = .{ .row_begin = frame.row_begin, .row_end = row,
                .col_begin = frame.col_begin, .col_end = best_column + 1 };
            top += 1;
        }
    }
}

export fn monge_dag_fixed_edge_shortest_path(input_opt: ?[*]const i64, length: usize) i64 {
    if (input_opt == null or length < 2 or length > MaxInput) return -1;
    const input = input_opt.?[0..length];
    if (input[0] < 1 or input[0] > @as(i64, @intCast(MaxN)) or input[1] < 1 or input[1] > input[0]) return -1;
    const n: usize = @intCast(input[0]);
    const layers: usize = @intCast(input[1]);
    if (length != 2 + n * (n + 1) / 2) return -1;

    var cost: [Side * Side]i64 = @splat(0);
    var offset: usize = 2;
    for (0..n) |u| {
        for (u + 1..n + 1) |v| {
            const weight = input[offset];
            offset += 1;
            if (weight < 0 or weight > 1_000_000) return -1;
            cost[u * Side + v] = weight;
        }
    }
    for (0..n - 1) |u| {
        for (u + 2..n) |v| {
            if (cost[u * Side + v] + cost[(u + 1) * Side + v + 1] >
                cost[u * Side + v + 1] + cost[(u + 1) * Side + v]) return -1;
        }
    }
    var dp: [Side]i64 = @splat(Inf);
    dp[0] = 0;
    for (1..layers + 1) |layer| {
        var next: [Side]i64 = @splat(Inf);
        mongeLayer(n, layer, &dp, &cost, &next);
        dp = next;
    }
    return dp[n];
}
