const max_n: usize = 64;
const max_q: usize = 64;
const max_input_values: usize = 195;

fn findRoot(parent: *[max_n]usize, node_input: usize) usize {
    var node = node_input;
    var root = node;
    while (parent[root] != root) root = parent[root];
    while (parent[node] != node) {
        const next = parent[node];
        parent[node] = root;
        node = next;
    }
    return root;
}

export fn arpa_offline_rmq(input_opt: ?[*]const i64, length: usize) i64 {
    if (input_opt == null or length < 2 or length > max_input_values) return -1;
    const input = input_opt.?;
    if (input[0] < 1 or input[0] > @as(i64, @intCast(max_n)) or
        input[1] < 0 or input[1] > @as(i64, @intCast(max_q))) return -1;
    const n: usize = @intCast(input[0]);
    const q: usize = @intCast(input[1]);
    if (length != 2 + n + 2 * q) return -1;
    for (0..n) |i| if (input[2 + i] < -1000 or input[2 + i] > 1000) return -1;
    const query_start = 2 + n;
    for (0..q) |j| {
        const left = input[query_start + 2 * j];
        const right = input[query_start + 2 * j + 1];
        if (left < 0 or left > right or right >= @as(i64, @intCast(n))) return -1;
    }
    var parent = [_]usize{0} ** max_n;
    var stack = [_]usize{0} ** max_n;
    var head = [_]i64{-1} ** max_n;
    var next_query = [_]i64{0} ** max_q;
    for (0..n) |i| parent[i] = i;
    for (0..q) |j| {
        const right: usize = @intCast(input[query_start + 2 * j + 1]);
        next_query[j] = head[right];
        head[right] = @intCast(j);
    }
    var stack_size: usize = 0;
    var checksum: i64 = 0;
    for (0..n) |right| {
        while (stack_size > 0 and input[2 + stack[stack_size - 1]] > input[2 + right]) {
            stack_size -= 1;
            parent[stack[stack_size]] = right;
        }
        stack[stack_size] = right;
        stack_size += 1;
        var query = head[right];
        while (query >= 0) {
            const ordinal: usize = @intCast(query);
            const left: usize = @intCast(input[query_start + 2 * ordinal]);
            const index = findRoot(&parent, left);
            checksum += @as(i64, @intCast(ordinal + 1)) * @as(i64, @intCast(index + 1));
            query = next_query[ordinal];
        }
    }
    return checksum;
}
