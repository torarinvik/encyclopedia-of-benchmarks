const max_n: usize = 31;
const max_q: usize = 32;
const max_input: usize = 129;
const max_bits: usize = 2 * max_n;
const max_output_words: usize = 4 + max_q;

fn bitAt(bits: u64, position: usize) bool {
    return ((bits >> @intCast(position - 1)) & 1) != 0;
}

fn findClose(bits: u64, bit_length: usize, start: usize) usize {
    var balance: isize = 0;
    var position = start;
    while (position <= bit_length) : (position += 1) {
        balance += if (bitAt(bits, position)) 1 else -1;
        if (balance == 0) return position;
    }
    return bit_length + 1;
}

fn findOpen(bits: u64, position: usize) usize {
    if (bitAt(bits, position)) return position;
    var balance: isize = 0;
    var candidate = position;
    while (candidate > 0) : (candidate -= 1) {
        balance += if (bitAt(bits, candidate)) -1 else 1;
        if (balance == 0) return candidate;
    }
    return 0;
}

fn previousZero(bits: u64, position: usize) usize {
    var candidate = position;
    while (candidate > 1) : (candidate -= 1) {
        if (!bitAt(bits, candidate - 1)) return candidate - 1;
    }
    return 0;
}

fn writeI64Le(output: [*]u8, offset: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |byte| output[offset + byte] = @truncate(bits >> @intCast(8 * byte));
}

export fn dfuds_ordered_tree_navigation(input_opt: ?[*]const i64, length: usize,
    output_opt: ?[*]u8, capacity: usize) i64 {
    if (input_opt == null or length < 2 or length > max_input) return -1;
    const input = input_opt.?;
    const n_value = input[0];
    const q_value = input[1];
    if (n_value < 1 or n_value > @as(i64, @intCast(max_n)) or
        q_value < 0 or q_value > @as(i64, @intCast(max_q))) return -1;
    const n: usize = @intCast(n_value);
    const q: usize = @intCast(q_value);
    if (length != 2 + n - 1 + 3 * q) return -1;

    var parent: [max_n]usize = @splat(0);
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
        if (opcode == 0 or opcode == 2) {
            if (argument != 0) return -1;
        } else if (opcode == 1) {
            if (argument < 0 or argument > n_value) return -1;
        } else return -1;
    }

    var order: [max_n]usize = @splat(0);
    var stack_node: [max_n]usize = @splat(0);
    var next_child: [max_n]usize = @splat(0);
    var order_count: usize = 1;
    var depth: usize = 1;
    while (depth > 0) {
        const frame = depth - 1;
        const node = stack_node[frame];
        var child = next_child[frame];
        while (child < n and parent[child] != node) child += 1;
        if (child < n) {
            next_child[frame] = child + 1;
            order[order_count] = child;
            order_count += 1;
            stack_node[depth] = child;
            next_child[depth] = 1;
            depth += 1;
        } else {
            depth -= 1;
        }
    }
    if (order_count != n) return -1;

    var descriptor: [max_n]usize = @splat(0);
    var position_to_node: [max_bits + 2]i32 = @splat(-1);
    var packed: u64 = 1;
    var bit_length: usize = 1;
    for (0..n) |node| {
        var degree: usize = 0;
        for (1..n) |child| {
            if (parent[child] == order[node]) degree += 1;
        }
        descriptor[node] = bit_length + 1;
        position_to_node[descriptor[node]] = @intCast(node);
        for (0..degree) |_| {
            packed |= @as(u64, 1) << @intCast(bit_length);
            bit_length += 1;
        }
        bit_length += 1;
    }
    if (bit_length != 2 * n) return -1;

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
        const start = descriptor[node];
        var degree: usize = 0;
        while (start + degree <= bit_length and bitAt(packed, start + degree)) degree += 1;
        var answer: i64 = -1;
        if (opcode == 0) {
            answer = @intCast(degree);
        } else if (opcode == 1) {
            if (@as(usize, @intCast(argument)) < degree) {
                const target = start + degree - (@as(usize, @intCast(argument)) + 1);
                const child_start = findClose(packed, bit_length, target) + 1;
                if (child_start > max_bits + 1 or position_to_node[child_start] < 0) return -1;
                answer = @as(i64, position_to_node[child_start]);
            }
        } else if (node != 0) {
            const matched_open = findOpen(packed, start - 1);
            const parent_position = previousZero(packed, matched_open) + 1;
            if (parent_position == 1) {
                answer = 0;
            } else if (parent_position <= max_bits + 1 and position_to_node[parent_position] >= 0) {
                answer = @as(i64, position_to_node[parent_position]);
            } else return -1;
        }
        words[4 + index] = answer;
    }

    const required = 8 * (4 + q);
    if (output_opt == null or capacity < required) return -2;
    const output = output_opt.?;
    for (0..4 + q) |index| writeI64Le(output, 8 * index, words[index]);
    return @intCast(required);
}
