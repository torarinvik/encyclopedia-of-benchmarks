const MAX_TEXT_LENGTH: usize = 64;
const MAX_PATTERN_LENGTH: usize = 16;
const MAX_INPUT_LENGTH: usize = 83;
const MAX_NODES: usize = 1 + MAX_TEXT_LENGTH * (MAX_TEXT_LENGTH + 1) / 2;

fn findChild(first_child: *const [MAX_NODES]i32, next_sibling: *const [MAX_NODES]i32,
    edge_code: *const [MAX_NODES]u8, parent: usize, code: u8) ?usize {
    var child = first_child[parent];
    while (child >= 0) {
        const index: usize = @intCast(child);
        if (edge_code[index] == code) return index;
        child = next_sibling[index];
    }
    return null;
}

export fn suffix_trie_search(input: ?[*]const i64, input_length: usize) i64 {
    const values = input orelse return -1;
    if (input_length < 2 or input_length > MAX_INPUT_LENGTH) return -1;
    const text_length_value = values[0];
    const pattern_length_value = values[1];
    if (text_length_value < 0 or text_length_value > 64 or
        pattern_length_value < 0 or pattern_length_value > 16) return -1;
    const text_length: usize = @intCast(text_length_value);
    const pattern_length: usize = @intCast(pattern_length_value);
    if (input_length != 2 + text_length + pattern_length) return -1;
    var text = [_]u8{0} ** MAX_TEXT_LENGTH;
    var pattern = [_]u8{0} ** MAX_PATTERN_LENGTH;
    for (0..text_length) |i| {
        const code = values[2 + i];
        if (code < 0 or code > 127) return -1;
        text[i] = @intCast(code);
    }
    for (0..pattern_length) |i| {
        const code = values[2 + text_length + i];
        if (code < 0 or code > 127) return -1;
        pattern[i] = @intCast(code);
    }

    var first_child = [_]i32{-1} ** MAX_NODES;
    var next_sibling = [_]i32{-1} ** MAX_NODES;
    var edge_code = [_]u8{0} ** MAX_NODES;
    var node_count: usize = 1;
    for (0..text_length) |start| {
        var parent: usize = 0;
        for (start..text_length) |position| {
            const code = text[position];
            const existing = findChild(&first_child, &next_sibling, &edge_code, parent, code);
            var child: usize = undefined;
            if (existing) |index| {
                child = index;
            } else {
                child = node_count;
                node_count += 1;
                edge_code[child] = code;
                next_sibling[child] = first_child[parent];
                first_child[parent] = @intCast(child);
            }
            parent = child;
        }
    }

    var node: usize = 0;
    for (0..pattern_length) |i| {
        const child = findChild(&first_child, &next_sibling, &edge_code, node, pattern[i]) orelse return 0;
        node = child;
    }
    return 1;
}
