const max_text_length: usize = 128;
const max_nodes: usize = max_text_length + 2;
const alphabet_size: usize = 26;

const Node = struct {
    length: i32 = 0,
    suffix_link: usize = 0,
    next: [alphabet_size]i32 = @splat(-1),
};

fn findExtendable(nodes: *const [max_nodes]Node, text: []const i64, position: usize, start: usize) usize {
    var node = start;
    while (true) {
        const preceding = @as(i64, @intCast(position)) - 1 - nodes[node].length;
        if (preceding >= 0 and text[@intCast(preceding)] == text[position]) return node;
        node = nodes[node].suffix_link;
    }
}

export fn eertree(values: ?[*]const i64, length: usize) i64 {
    if (values == null or length < 1 or length > max_text_length + 1) return -1;
    const packed = values.?;
    if (packed[0] < 0 or packed[0] > @as(i64, @intCast(max_text_length))) return -1;
    const text_length: usize = @intCast(packed[0]);
    if (length != text_length + 1) return -1;
    const text = packed[1 .. text_length + 1];
    for (text) |letter| if (letter < 0 or letter >= @as(i64, @intCast(alphabet_size))) return -1;

    var nodes: [max_nodes]Node = undefined;
    nodes[0] = .{};
    nodes[1] = .{};
    nodes[0].length = -1;
    nodes[0].suffix_link = 0;
    nodes[1].length = 0;
    nodes[1].suffix_link = 0;
    var node_count: usize = 2;
    var longest_suffix: usize = 1;
    var checksum: i64 = 0;

    for (0..text_length) |position| {
        const letter: usize = @intCast(text[position]);
        const parent = findExtendable(&nodes, text, position, longest_suffix);
        var next = nodes[parent].next[letter];
        if (next < 0) {
            next = @intCast(node_count);
            node_count += 1;
            const new_index: usize = @intCast(next);
            nodes[new_index] = .{};
            nodes[new_index].length = nodes[parent].length + 2;
            nodes[parent].next[letter] = next;
            if (nodes[new_index].length == 1) {
                nodes[new_index].suffix_link = 1;
            } else {
                const suffix_parent = findExtendable(&nodes, text, position, nodes[parent].suffix_link);
                const suffix = nodes[suffix_parent].next[letter];
                if (suffix < 0) return -1;
                nodes[new_index].suffix_link = @intCast(suffix);
            }
        }
        longest_suffix = @intCast(next);
        checksum += @as(i64, @intCast(position + 1)) * @as(i64, @intCast(node_count - 2));
    }
    return checksum;
}
