const max_n: usize = 31;
const max_q: usize = 32;
const max_input: usize = 129;
const max_bits: usize = 2 * max_n;
const max_output_words: usize = 4 + max_q;

fn writeI64Le(output: [*]u8, offset: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |byte| output[offset + byte] = @truncate(bits >> @intCast(8 * byte));
}

export fn bp_ordered_tree_navigation(input_opt: ?[*]const i64, length: usize,
    output_opt: ?[*]u8, capacity: usize) i64 {
    if (input_opt == null or length < 2 or length > max_input) return -1;
    const input = input_opt.?;
    const n_value = input[0];
    const q_value = input[1];
    if (n_value < 1 or n_value > @as(i64, @intCast(max_n)) or
        q_value < 0 or q_value > @as(i64, @intCast(max_q))) return -1;
    const n: usize = @intCast(n_value);
    const q: usize = @intCast(q_value);
    const bit_length = 2 * n;
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
        const first = input[offset + 1];
        const second = input[offset + 2];
        if (opcode == 0 or opcode == 1) {
            if (first < 0 or first > @as(i64, @intCast(bit_length)) or
                second < -@as(i64, @intCast(bit_length)) or second > @as(i64, @intCast(bit_length))) return -1;
        } else if (opcode == 2) {
            if (first < 0 or second < first or second >= @as(i64, @intCast(bit_length))) return -1;
        } else if (opcode == 3 or opcode == 4 or opcode == 5) {
            if (first < 0 or first >= @as(i64, @intCast(bit_length)) or second != 0) return -1;
        } else return -1;
    }

    var bits: [max_bits]u8 = @splat(0);
    var stack_node: [max_n + 1]usize = @splat(0);
    var next_child: [max_n + 1]usize = @splat(0);
    var bit_count: usize = 1;
    var depth: usize = 1;
    bits[0] = 1;
    next_child[0] = 1;
    while (depth > 0) {
        const frame = depth - 1;
        const node = stack_node[frame];
        var child = next_child[frame];
        while (child < n and parent[child] != node) child += 1;
        if (child < n) {
            next_child[frame] = child + 1;
            bits[bit_count] = 1;
            bit_count += 1;
            stack_node[depth] = child;
            next_child[depth] = 1;
            depth += 1;
        } else {
            bits[bit_count] = 0;
            bit_count += 1;
            depth -= 1;
        }
    }
    if (bit_count != bit_length) return -1;

    var excess: [max_bits + 1]i64 = @splat(0);
    var packed: u64 = 0;
    for (0..bit_length) |position| {
        if (bits[position] != 0) {
            packed |= @as(u64, 1) << @intCast(position);
            excess[position + 1] = excess[position] + 1;
        } else {
            excess[position + 1] = excess[position] - 1;
        }
    }
    for (0..q) |index| {
        const offset = query_base + 3 * index;
        const opcode = input[offset];
        const first: usize = @intCast(input[offset + 1]);
        if (opcode == 3 and bits[first] == 0) return -1;
        if (opcode == 4 and bits[first] != 0) return -1;
        if (opcode == 5 and bits[first] == 0) return -1;
    }

    var words: [max_output_words]i64 = @splat(0);
    words[0] = n_value;
    words[1] = @intCast(bit_length);
    words[2] = @intCast(packed);
    words[3] = q_value;
    for (0..q) |index| {
        const offset = query_base + 3 * index;
        const opcode = input[offset];
        const first: usize = @intCast(input[offset + 1]);
        const second = input[offset + 2];
        var answer: i64 = -1;
        if (opcode == 0 or opcode == 1) {
            const target = excess[first] + second;
            if (opcode == 0) {
                answer = @intCast(bit_length + 1);
                for (first + 1..bit_length + 1) |position| {
                    if (excess[position] == target) {
                        answer = @intCast(position);
                        break;
                    }
                }
            } else {
                answer = 0;
                var position = first;
                while (position > 0) {
                    position -= 1;
                    if (excess[position] == target) {
                        answer = @intCast(position);
                        break;
                    }
                }
            }
        } else if (opcode == 2) {
            const right: usize = @intCast(second);
            var best = first;
            for (first + 1..right + 1) |position| {
                if (excess[position + 1] < excess[best + 1]) best = position;
            }
            answer = @intCast(best);
        } else if (opcode == 3) {
            const target = excess[first + 1] - 1;
            for (first + 2..bit_length + 1) |position| {
                if (excess[position] == target) {
                    answer = @intCast(position - 1);
                    break;
                }
            }
        } else if (opcode == 4) {
            const target = excess[first + 1];
            var position = first + 1;
            while (position > 0) {
                position -= 1;
                if (excess[position] == target) {
                    answer = @intCast(position);
                    break;
                }
            }
        } else if (first == 0) {
            answer = -1;
        } else {
            const target = excess[first + 1] - 2;
            var position = first + 1;
            while (position > 0) {
                position -= 1;
                if (excess[position] == target) {
                    answer = @intCast(position);
                    break;
                }
            }
        }
        words[4 + index] = answer;
    }

    const output_words = 4 + q;
    const required = 8 * output_words;
    if (output_opt == null or capacity < required) return -2;
    const output = output_opt.?;
    for (0..output_words) |index| writeI64Le(output, 8 * index, words[index]);
    return @intCast(required);
}
