const N: usize = 16;
const D: usize = 4;
const MAX_EDGES: usize = 32;
const MAX_T: usize = 4;
const MAX_R: usize = 8;
const MAX_L: usize = 8;
const MAX_INPUT: usize = 330;

fn putI64(out: [*]u8, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |byte| out[byte] = @truncate(bits >> @intCast(8 * byte));
}

export fn sublinear_bipartiteness_walk_tester(input_opt: ?[*]const i64, length: usize,
    output_opt: ?[*]u8, capacity: usize) i64 {
    if (input_opt == null or length < 8 or length > MAX_INPUT) return -1;
    const input = input_opt.?;
    if (input[0] < 1 or input[0] > 16 or input[1] < 3 or input[1] > 4 or input[2] < 0 or input[2] > 32) return -1;
    const n: usize = @intCast(input[0]);
    const d: usize = @intCast(input[1]);
    const m: usize = @intCast(input[2]);
    if (m > n * d / 2) return -1;
    const suffix = 3 + 2 * m;
    if (length < suffix + 4) return -1;
    if (input[suffix] < 1 or input[suffix] > 4 or input[suffix + 1] < 1 or input[suffix + 1] > 8 or input[suffix + 2] < 1 or input[suffix + 2] > 8) return -1;
    const starts_count: usize = @intCast(input[suffix]);
    const walks: usize = @intCast(input[suffix + 1]);
    const steps: usize = @intCast(input[suffix + 2]);
    if (length != suffix + 3 + starts_count + starts_count * walks * steps) return -1;
    var adjacent: [N][N]bool = @splat(@splat(false));
    var neighbors: [N][D]usize = @splat(@splat(0));
    var degree: [N]usize = @splat(0);
    for (0..m) |edge| {
        const a0 = input[3 + 2 * edge];
        const b0 = input[4 + 2 * edge];
        if (a0 < 0 or b0 < 0 or a0 >= @as(i64, @intCast(n)) or b0 >= @as(i64, @intCast(n)) or a0 >= b0) return -1;
        const a: usize = @intCast(a0);
        const b: usize = @intCast(b0);
        if (adjacent[a][b] or degree[a] >= d or degree[b] >= d) return -1;
        adjacent[a][b] = true;
        adjacent[b][a] = true;
        var at = degree[a];
        degree[a] += 1;
        while (at > 0 and neighbors[a][at - 1] > b) : (at -= 1) neighbors[a][at] = neighbors[a][at - 1];
        neighbors[a][at] = b;
        at = degree[b];
        degree[b] += 1;
        while (at > 0 and neighbors[b][at - 1] > a) : (at -= 1) neighbors[b][at] = neighbors[b][at - 1];
        neighbors[b][at] = a;
    }
    const starts_at = suffix + 3;
    const draws_at = starts_at + starts_count;
    for (0..starts_count) |t| if (input[starts_at + t] < 0 or input[starts_at + t] >= @as(i64, @intCast(n))) return -1;
    const draw_count = starts_count * walks * steps;
    for (0..draw_count) |index| if (input[draws_at + index] < 0 or input[draws_at + index] >= @as(i64, @intCast(2 * d))) return -1;

    var accepted = true;
    var draw: usize = 0;
    for (0..starts_count) |t| {
        if (!accepted) break;
        var seen: [N][2]bool = @splat(@splat(false));
        const start: usize = @intCast(input[starts_at + t]);
        seen[start][0] = true;
        for (0..walks) |_| {
            if (!accepted) break;
            var vertex = start;
            var parity: usize = 0;
            for (0..steps) |_| {
                const choice: usize = @intCast(input[draws_at + draw]);
                draw += 1;
                if (choice < degree[vertex]) { vertex = neighbors[vertex][choice]; parity ^= 1; }
                seen[vertex][parity] = true;
                if (seen[vertex][1 - parity]) { accepted = false; break; }
            }
        }
    }
    if (output_opt == null or capacity < 8) return -2;
    var staged: [8]u8 = @splat(0);
    putI64(&staged, if (accepted) 1 else 0);
    @memcpy(output_opt.?[0..8], staged[0..8]);
    return 8;
}
