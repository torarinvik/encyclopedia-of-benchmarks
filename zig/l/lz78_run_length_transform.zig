const max_text: usize = 32;
const max_input: usize = 34;
const max_trie_nodes: usize = 33;
const max_tokens: usize = 32;
const max_output: usize = 776;

fn put64(output: *[max_output]u8, offset: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |byte| output[offset + byte] = @truncate(bits >> @intCast(byte * 8));
}

export fn lz78_run_length_transform(input_opt: ?[*]const i64, input_length: usize,
    output_opt: ?[*]u8, capacity: usize) i64 {
    if (input_length < 1 or input_length > max_input) return -1;
    const input = input_opt orelse return -1;
    if (input[0] < 0 or input[0] > max_text) return -1;
    const n: usize = @intCast(input[0]);
    if (input_length != n + 1) return -1;
    for (0..n) |i| if (input[i + 1] < 1 or input[i + 1] > 3) return -1;

    var transformed = [_]i64{0} ** max_text;
    var transformed_length: usize = 0;
    var position: usize = 0;
    while (position < n) {
        const symbol = input[position + 1];
        var end = position + 1;
        while (end < n and input[end + 1] == symbol) end += 1;
        const run_length = end - position;
        var highest_bit: usize = 0;
        var value = run_length;
        while (value > 1) {
            value >>= 1;
            highest_bit += 1;
        }
        var bits = highest_bit + 1;
        while (bits > 0) {
            bits -= 1;
            transformed[transformed_length] = if ((run_length >> bits) & 1 != 0) symbol else 0;
            transformed_length += 1;
        }
        position = end;
    }

    var children = [_][4]usize{[_]usize{0} ** 4} ** max_trie_nodes;
    var tokens = [_][3]i64{[_]i64{0} ** 3} ** max_tokens;
    var token_count: usize = 0;
    var text_position: usize = 0;
    var next_phrase_id: usize = 1;
    while (text_position < transformed_length) {
        var node: usize = 0;
        var end = text_position;
        while (end < transformed_length) {
            const child = children[node][@intCast(transformed[end])];
            if (child == 0) break;
            node = child;
            end += 1;
        }
        if (end == transformed_length) {
            if (node != 0) {
                tokens[token_count] = .{@intCast(node), 0, 1};
                token_count += 1;
            }
            break;
        }
        const symbol: usize = @intCast(transformed[end]);
        tokens[token_count] = .{@intCast(node), @intCast(symbol), 0};
        token_count += 1;
        children[node][symbol] = next_phrase_id;
        next_phrase_id += 1;
        text_position = end + 1;
    }

    const output_bytes = 8 + 24 * token_count;
    var staged = [_]u8{0} ** max_output;
    put64(&staged, 0, @intCast(token_count));
    for (0..token_count) |token| {
        for (0..3) |field| put64(&staged, 8 + 24 * token + 8 * field, tokens[token][field]);
    }
    const output = output_opt orelse return -2;
    if (capacity < output_bytes) return -2;
    if (output_bytes > 0) @memcpy(output[0..output_bytes], staged[0..output_bytes]);
    return @intCast(output_bytes);
}
