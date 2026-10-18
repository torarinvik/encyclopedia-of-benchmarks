const MAX_NODES: usize = 8;
const MAX_OPERATIONS: usize = 24;
const MAX_PARSEABLE_INPUT_LENGTH: usize = 98;
const MAX_OUTPUT_WORDS: usize = 144;

fn pushWord(words: *[MAX_OUTPUT_WORDS]i64, count: *usize, value: i64) void {
    words[count.*] = value;
    count.* += 1;
}

fn pushRecord(words: *[MAX_OUTPUT_WORDS]i64, count: *usize, opcode: i64,
    payload: []const i64) void {
    pushWord(words, count, opcode);
    pushWord(words, count, @intCast(payload.len));
    for (payload) |value| pushWord(words, count, value);
}

export fn undirected_adjacency_list_graph(input: [*c]const i64, input_length: usize,
    output: [*c]u8, output_capacity: usize) i64 {
    if (input == null or input_length < 1 or input_length > MAX_PARSEABLE_INPUT_LENGTH) return -1;
    if (input[0] < 0 or input[0] > MAX_OPERATIONS) return -1;
    const operation_count: usize = @intCast(input[0]);
    if (input_length != 1 + 4 * operation_count) return -1;

    var words = [_]i64{0} ** MAX_OUTPUT_WORDS;
    var word_count: usize = 0;
    var edge_weights = [_][MAX_NODES]i64{[_]i64{0} ** MAX_NODES} ** MAX_NODES;
    var has_edge = [_][MAX_NODES]bool{[_]bool{false} ** MAX_NODES} ** MAX_NODES;
    var node_count: usize = 0;

    for (0..operation_count) |operation_index| {
        const base = 1 + 4 * operation_index;
        const opcode = input[base];
        const first = input[base + 1];
        const second = input[base + 2];
        const third = input[base + 3];
        if (opcode < 0 or opcode > 4) return -1;

        if (opcode == 0 or opcode == 4) {
            if (first != 0 or second != 0 or third != 0) return -1;
        } else if (opcode == 1) {
            if (first < -2147483648 or first > 2147483647 or
                second < -2147483648 or second > 2147483647 or
                third < -2147483648 or third > 2147483647) return -1;
        } else if (opcode == 2) {
            if (first < -2147483648 or first > 2147483647 or second != 0 or third != 0) return -1;
        } else if (first < -2147483648 or first > 2147483647 or
            second < -2147483648 or second > 2147483647 or third != 0) return -1;

        if (opcode == 0) {
            if (node_count >= MAX_NODES) return -1;
            const payload = [_]i64{@intCast(node_count)};
            pushRecord(&words, &word_count, opcode, payload[0..]);
            node_count += 1;
        } else if (opcode == 1) {
            var added = false;
            if (first >= 0 and first < @as(i64, @intCast(node_count)) and
                second >= 0 and second < @as(i64, @intCast(node_count))) {
                const origin: usize = @intCast(first);
                const destination: usize = @intCast(second);
                if (!has_edge[origin][destination]) {
                    has_edge[origin][destination] = true;
                    has_edge[destination][origin] = true;
                    edge_weights[origin][destination] = third;
                    edge_weights[destination][origin] = third;
                    added = true;
                }
            }
            const payload = [_]i64{if (added) 1 else 0};
            pushRecord(&words, &word_count, opcode, payload[0..]);
        } else if (opcode == 2) {
            if (first < 0 or first >= @as(i64, @intCast(node_count))) return -1;
            const origin: usize = @intCast(first);
            var payload = [_]i64{0} ** (MAX_NODES + 1);
            var neighbor_count: usize = 0;
            for (0..node_count) |neighbor| {
                if (has_edge[origin][neighbor]) {
                    payload[neighbor_count + 1] = @intCast(neighbor);
                    neighbor_count += 1;
                }
            }
            payload[0] = @intCast(neighbor_count);
            pushRecord(&words, &word_count, opcode, payload[0 .. neighbor_count + 1]);
        } else if (opcode == 3) {
            if (first < 0 or first >= @as(i64, @intCast(node_count))) return -1;
            const origin: usize = @intCast(first);
            var present = false;
            var weight: i64 = 0;
            if (second >= 0 and second < @as(i64, @intCast(node_count))) {
                const destination: usize = @intCast(second);
                if (has_edge[origin][destination]) {
                    present = true;
                    weight = edge_weights[origin][destination];
                }
            }
            const payload = [_]i64{if (present) 1 else 0, weight};
            pushRecord(&words, &word_count, opcode, payload[0..]);
        } else {
            const payload = [_]i64{@intCast(node_count)};
            pushRecord(&words, &word_count, opcode, payload[0..]);
        }
    }

    const output_bytes = word_count * 8;
    if (output == null or output_capacity < output_bytes) return -2;
    for (0..word_count) |index| {
        const bits: u64 = @bitCast(words[index]);
        for (0..8) |byte| {
            const shift: u6 = @intCast(byte * 8);
            output[index * 8 + byte] = @truncate(bits >> shift);
        }
    }
    return @intCast(output_bytes);
}
