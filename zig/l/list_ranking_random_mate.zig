const max_n: usize = 8;
const max_rounds: usize = 32;
const max_input: usize = 275;
const max_output: usize = 64;

fn put64(output: [*]u8, position: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |byte| output[position + byte] = @truncate(bits >> @intCast(8 * byte));
}

export fn list_ranking_random_mate(input_opt: ?[*]const i64, length: usize,
    output_opt: ?[*]u8, capacity: usize) i64 {
    if (input_opt == null or length < 5 or length > max_input) return -1;
    const input = input_opt.?;
    const n64 = input[0];
    const head64 = input[1];
    if (n64 < 1 or n64 > 8 or head64 < 0 or head64 >= n64) return -1;
    const n: usize = @intCast(n64);
    const head: usize = @intCast(head64);
    if (length < 3 + 2*n) return -1;
    const rounds64 = input[2 + 2*n];
    if (rounds64 < 0 or rounds64 > 32 or length != 3 + 2*n + @as(usize, @intCast(rounds64))*n)
        return -1;
    const rounds: usize = @intCast(rounds64);
    var weight: [max_n]i64 = @splat(0);
    var successor: [max_n]i64 = @splat(0);
    var indegree: [max_n]usize = @splat(0);
    var tails: usize = 0;
    for (0..n) |index| {
        weight[index] = input[2 + index];
        successor[index] = input[2 + n + index];
        if (weight[index] < 1 or weight[index] > 10000 or successor[index] < -1 or successor[index] >= n64)
            return -1;
        if (successor[index] == -1) tails += 1 else {
            const target: usize = @intCast(successor[index]);
            indegree[target] += 1;
            if (indegree[target] > 1) return -1;
        }
    }
    if (tails != 1 or indegree[head] != 0) return -1;
    const coin_start = 3 + 2*n;
    for (0..rounds*n) |index| if (input[coin_start + index] < 0 or input[coin_start + index] > 1) return -1;

    var seen: [max_n]bool = @splat(false);
    var path_length: usize = 0;
    var node = head64;
    while (node != -1) {
        const index: usize = @intCast(node);
        if (seen[index] or path_length == n) return -1;
        seen[index] = true;
        path_length += 1;
        node = successor[index];
    }
    if (path_length != n) return -1;

    var active: [max_n]bool = @splat(false);
    var removal_round: [max_n]i32 = @splat(-1);
    for (0..n) |index| active[index] = true;
    for (0..rounds) |round| {
        if (successor[head] == -1) break;
        const old_successor = successor;
        const old_weight = weight;
        var remove: [max_n]bool = @splat(false);
        const coin_offset = coin_start + round*n;
        for (0..n) |index| {
            const target_value = old_successor[index];
            if (active[index] and target_value != -1 and input[coin_offset + index] == 0 and
                input[coin_offset + @as(usize, @intCast(target_value))] == 1) {
                const target: usize = @intCast(target_value);
                remove[target] = true;
                removal_round[target] = @intCast(round);
            }
        }
        for (0..n) |index| {
            const target_value = old_successor[index];
            if (active[index] and target_value != -1 and remove[@intCast(target_value)]) {
                const target: usize = @intCast(target_value);
                weight[index] = old_weight[index] + old_weight[target];
                successor[index] = old_successor[target];
            }
        }
        for (0..n) |index| if (remove[index]) { active[index] = false; };
    }
    if (successor[head] != -1) return -1;

    var rank = weight;
    var remaining = rounds;
    while (remaining > 0) {
        remaining -= 1;
        for (0..n) |index| if (removal_round[index] == @as(i32, @intCast(remaining)) and successor[index] != -1) {
            rank[index] += rank[@intCast(successor[index])];
        };
    }
    const output_bytes = 8*n;
    if (output_opt == null or capacity < output_bytes) return -2;
    const output = output_opt.?;
    var staged: [max_output]u8 = @splat(0);
    for (0..n) |index| put64(&staged, 8*index, rank[index]);
    for (0..output_bytes) |index| output[index] = staged[index];
    return @intCast(output_bytes);
}
