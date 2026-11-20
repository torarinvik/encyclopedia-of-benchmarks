const max_nodes: usize = 32;
const max_queries: usize = 32;
const max_input_words: usize = 130;
const max_output_words: usize = 4 + max_queries;

fn storeI64Le(output: [*]u8, offset: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |byte| output[offset + byte] = @truncate(bits >> @intCast(8 * byte));
}

export fn louds_ordered_tree_navigation(input_opt: ?[*]const i64, length: usize,
    output_opt: ?[*]u8, capacity: usize) i64 {
    if (input_opt == null or length < 2 or length > max_input_words) return -1;
    const input = input_opt.?;
    const n_value = input[0];
    const q_value = input[1];
    if (n_value < 1 or n_value > @as(i64, @intCast(max_nodes)) or
        q_value < 0 or q_value > @as(i64, @intCast(max_queries))) return -1;
    const n: usize = @intCast(n_value);
    const q: usize = @intCast(q_value);
    if (length != 2 + n - 1 + 3 * q) return -1;

    var parent: [max_nodes]usize = @splat(0);
    for (1..n) |vertex| {
        const value = input[1 + vertex];
        if (value < 0 or value >= @as(i64, @intCast(vertex))) return -1;
        parent[vertex] = @intCast(value);
    }
    const query_base = n + 1;
    for (0..q) |index| {
        const offset = query_base + 3 * index;
        const opcode = input[offset];
        const node = input[offset + 1];
        const argument = input[offset + 2];
        if (node < 0 or node >= n_value) return -1;
        if (opcode == 0 or opcode == 1) {
            if (argument != 0) return -1;
        } else if (opcode == 2) {
            if (argument < 0 or argument > n_value) return -1;
        } else return -1;
    }

    var order: [max_nodes]usize = @splat(0);
    var order_count: usize = 1;
    var cursor: usize = 0;
    while (cursor < order_count) : (cursor += 1) {
        const vertex = order[cursor];
        for (1..n) |child| {
            if (parent[child] == vertex) {
                order[order_count] = child;
                order_count += 1;
            }
        }
    }
    if (order_count != n) return -1;

    var degree: [max_nodes]usize = @splat(0);
    for (0..n) |node| {
        for (1..n) |child| {
            if (parent[child] == order[node]) degree[node] += 1;
        }
    }

    var packed: u64 = 0;
    var bit_length: usize = 0;
    for (0..n) |node| {
        for (0..degree[node]) |_| {
            packed |= @as(u64, 1) << @intCast(bit_length);
            bit_length += 1;
        }
        bit_length += 1;
    }

    var decoded: [max_nodes]usize = @splat(0);
    var rank_prefix: [max_nodes + 1]usize = @splat(0);
    var bit_position: usize = 0;
    var previous_zero: isize = -1;
    for (0..n) |node| {
        while (bit_position < bit_length and ((packed >> @intCast(bit_position)) & 1) != 0)
            bit_position += 1;
        decoded[node] = @intCast(@as(isize, @intCast(bit_position)) - previous_zero - 1);
        previous_zero = @intCast(bit_position);
        bit_position += 1;
        rank_prefix[node + 1] = rank_prefix[node] + decoded[node];
    }

    var words: [max_output_words]i64 = @splat(0);
    words[0] = n_value;
    words[1] = @intCast(bit_length);
    words[2] = @intCast(packed);
    words[3] = q_value;
    for (0..q) |index| {
        const offset = query_base + 3 * index;
        const opcode = input[offset];
        const node: usize = @intCast(input[offset + 1]);
        const argument = input[offset + 2];
        var answer: i64 = -1;
        if (opcode == 0) {
            answer = @intCast(decoded[node]);
        } else if (opcode == 1) {
            if (node != 0) {
                for (0..n) |candidate| {
                    if (rank_prefix[candidate + 1] >= node) {
                        answer = @intCast(candidate);
                        break;
                    }
                }
            }
        } else if (@as(usize, @intCast(argument)) < decoded[node]) {
            answer = @intCast(1 + rank_prefix[node] + @as(usize, @intCast(argument)));
        }
        words[4 + index] = answer;
    }

    const output_words = 4 + q;
    const required = 8 * output_words;
    if (output_opt == null or capacity < required) return -2;
    const output = output_opt.?;
    for (0..output_words) |index| storeI64Le(output, 8 * index, words[index]);
    return @intCast(required);
}
