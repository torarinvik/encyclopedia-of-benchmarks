const max_n: usize = 16;
const max_input: usize = 34;
const max_output: usize = 128;

fn put64(output: [*]u8, position: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |byte| output[position + byte] = @truncate(bits >> @intCast(8 * byte));
}

export fn list_ranking_independent_set_contraction(
    input_opt: ?[*]const i64, length: usize,
    output_opt: ?[*]u8, capacity: usize) i64 {
    if (input_opt == null or length < 4 or length > max_input) return -1;
    const input = input_opt.?;
    const n64 = input[0];
    const head64 = input[1];
    if (n64 < 1 or n64 > 16 or length != 2 + 2 * @as(usize, @intCast(n64)) or
        head64 < 0 or head64 >= n64) return -1;
    const n: usize = @intCast(n64);
    const head: usize = @intCast(head64);
    var weight: [max_n]i64 = @splat(0);
    var successor: [max_n]i64 = @splat(0);
    var indegree: [max_n]usize = @splat(0);
    var tail_count: usize = 0;
    for (0..n) |node| {
        weight[node] = input[2 + node];
        successor[node] = input[2 + n + node];
        if (weight[node] < 1 or weight[node] > 10000 or
            successor[node] < -1 or successor[node] >= n64) return -1;
        if (successor[node] == -1) {
            tail_count += 1;
        } else {
            const next: usize = @intCast(successor[node]);
            indegree[next] += 1;
            if (indegree[next] > 1) return -1;
        }
    }
    if (tail_count != 1 or indegree[head] != 0) return -1;

    var path: [max_n]usize = @splat(0);
    var seen: [max_n]bool = @splat(false);
    var path_length: usize = 0;
    var node = head64;
    while (node != -1) {
        const index: usize = @intCast(node);
        if (seen[index] or path_length == n) return -1;
        seen[index] = true;
        path[path_length] = index;
        path_length += 1;
        node = successor[index];
    }
    if (path_length != n) return -1;
    const output_bytes = 8 * n;
    if (output_opt == null or capacity < output_bytes) return -2;
    const output = output_opt.?;

    var removed_node: [max_n]usize = @splat(0);
    var removed_successor: [max_n]usize = @splat(0);
    var old_successor_weight: [max_n]i64 = @splat(0);
    var removed_count: usize = 0;
    while (path_length > 1) {
        var counts: [3]usize = @splat(0);
        for (0..path_length - 1) |position| counts[position % 3] += 1;
        var color: usize = 0;
        for (1..3) |candidate| {
            if (counts[candidate] > counts[color]) color = candidate;
        }
        var write: usize = 0;
        for (0..path_length) |position| {
            const current = path[position];
            if (position + 1 < path_length and position % 3 == color) {
                const next = path[position + 1];
                removed_node[removed_count] = current;
                removed_successor[removed_count] = next;
                old_successor_weight[removed_count] = weight[next];
                removed_count += 1;
                weight[next] += weight[current];
            } else {
                path[write] = current;
                write += 1;
            }
        }
        if (write == path_length) return -1;
        path_length = write;
    }

    var rank: [max_n]i64 = @splat(0);
    rank[path[0]] = weight[path[0]];
    while (removed_count > 0) {
        removed_count -= 1;
        const current = removed_node[removed_count];
        const next = removed_successor[removed_count];
        rank[current] = rank[next] - old_successor_weight[removed_count];
    }
    var staged: [max_output]u8 = @splat(0);
    for (0..n) |index| put64(&staged, 8 * index, rank[index]);
    for (0..output_bytes) |index| output[index] = staged[index];
    return @intCast(output_bytes);
}
