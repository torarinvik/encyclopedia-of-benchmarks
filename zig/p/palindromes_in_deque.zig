const MAX_QUERIES: usize = 32;
const MAX_NODES: usize = MAX_QUERIES + 2;
const ALPHABET: usize = 26;

const Node = struct {
    length: i32,
    link: usize,
    next: [ALPHABET]i32,
};

fn extendable(nodes: *const [MAX_NODES]Node, text: []const i32,
    position: usize, start: usize) usize {
    var node = start;
    while (true) {
        const preceding = @as(i32, @intCast(position)) - nodes[node].length - 1;
        if (preceding >= 0 and text[@intCast(preceding)] == text[position]) return node;
        node = nodes[node].link;
    }
}

fn summarize(text: []const i32) [3]i64 {
    var nodes: [MAX_NODES]Node = undefined;
    for (&nodes) |*node| {
        node.length = 0;
        node.link = 0;
        for (&node.next) |*transition| transition.* = -1;
    }
    nodes[0].length = -1;
    var node_count: usize = 2;
    var last: usize = 1;
    var longest_prefix: i64 = 0;
    for (text, 0..) |character, position| {
        const letter: usize = @intCast(character);
        const parent = extendable(&nodes, text, position, last);
        var child = nodes[parent].next[letter];
        if (child < 0) {
            const new_child = node_count;
            node_count += 1;
            nodes[new_child].length = nodes[parent].length + 2;
            if (nodes[new_child].length == 1) {
                nodes[new_child].link = 1;
            } else {
                const suffix_parent = extendable(&nodes, text, position, nodes[parent].link);
                nodes[new_child].link = @intCast(nodes[suffix_parent].next[letter]);
            }
            nodes[parent].next[letter] = @intCast(new_child);
            child = @intCast(new_child);
        }
        last = @intCast(child);
        if (nodes[last].length == @as(i32, @intCast(position + 1)))
            longest_prefix = @intCast(position + 1);
    }
    return .{ @intCast(node_count - 2), longest_prefix, nodes[last].length };
}

fn storeI64Le(output: [*]u8, offset: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |byte| output[offset + byte] = @truncate(bits >> @intCast(8 * byte));
}

export fn palindromes_in_deque(input_opt: ?[*]const i64, length: usize,
    output_opt: ?[*]u8, capacity: usize) callconv(.c) i64 {
    if (input_opt == null or length < 1 or length > 1 + 2 * MAX_QUERIES) return -1;
    const input = input_opt.?;
    const query_value = input[0];
    if (query_value < 1 or query_value > MAX_QUERIES) return -1;
    const queries: usize = @intCast(query_value);
    if (length != 1 + 2 * queries) return -1;

    var size: usize = 0;
    for (0..queries) |query| {
        const operation = input[1 + 2 * query];
        const letter = input[2 + 2 * query];
        if (operation == 0 or operation == 1) {
            if (letter < 0 or letter >= @as(i64, @intCast(ALPHABET))) return -1;
            size += 1;
        } else if (operation == 2 or operation == 3) {
            if (letter != 0 or size == 0) return -1;
            size -= 1;
        } else return -1;
    }
    if (output_opt == null or capacity < 24 * queries) return -2;
    const output = output_opt.?;

    var text_storage: [MAX_QUERIES]i32 = [_]i32{0} ** MAX_QUERIES;
    size = 0;
    for (0..queries) |query| {
        const operation: usize = @intCast(input[1 + 2 * query]);
        const letter: i32 = @intCast(input[2 + 2 * query]);
        if (operation == 0) {
            var index = size;
            while (index > 0) : (index -= 1) text_storage[index] = text_storage[index - 1];
            text_storage[0] = letter;
            size += 1;
        } else if (operation == 1) {
            text_storage[size] = letter;
            size += 1;
        } else if (operation == 2) {
            var index: usize = 1;
            while (index < size) : (index += 1) text_storage[index - 1] = text_storage[index];
            size -= 1;
        } else {
            size -= 1;
        }
        const summary = summarize(text_storage[0..size]);
        const offset = 24 * query;
        storeI64Le(output, offset, summary[0]);
        storeI64Le(output, offset + 8, summary[1]);
        storeI64Le(output, offset + 16, summary[2]);
    }
    return @intCast(24 * queries);
}
