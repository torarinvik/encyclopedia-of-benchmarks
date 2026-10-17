const MAX_INPUT_BYTES: usize = 256;
const MAX_TOKEN_BYTES: usize = 45;
const MAX_UNIQUE_WORDS: usize = 128;
const MAX_OUTPUT_BYTES: usize = 896;

const WordNode = struct {
    word: [MAX_TOKEN_BYTES + 1]u8,
    word_length: usize,
    frequency: u64,
    left: i32,
    right: i32,
};

fn asciiAlpha(value: i64) bool {
    return (value >= 65 and value <= 90) or (value >= 97 and value <= 122);
}

export fn word_frequency_bst(
    input: ?[*]const i64,
    length: usize,
    output: ?[*]u8,
    capacity: usize,
) i64 {
    if (input == null or length < 1 or length > MAX_INPUT_BYTES + 2) return -1;
    const input_ptr = input.?;
    const n_value = input_ptr[0];
    if (n_value < 0 or n_value > @as(i64, MAX_INPUT_BYTES)) return -1;
    const text_length: usize = @intCast(n_value);
    if (length != text_length + 1) return -1;
    for (0..text_length) |i| {
        if (input_ptr[i + 1] < 0 or input_ptr[i + 1] > 127) return -1;
    }

    var nodes: [MAX_UNIQUE_WORDS]WordNode = undefined;
    for (0..MAX_UNIQUE_WORDS) |i| {
        nodes[i] = .{
            .word = undefined,
            .word_length = 0,
            .frequency = 0,
            .left = -1,
            .right = -1,
        };
    }
    var used: usize = 0;
    var root: i32 = -1;
    var token: [MAX_TOKEN_BYTES + 1]u8 = undefined;
    var token_length: usize = 0;
    for (0..text_length + 1) |position| {
        const byte: i64 = if (position < text_length) input_ptr[position + 1] else -1;
        if (asciiAlpha(byte)) {
            if (token_length >= MAX_TOKEN_BYTES) return -1;
            token[token_length] = @intCast(if (byte >= 65 and byte <= 90) byte + 32 else byte);
            token_length += 1;
        } else if ((byte == 39 or byte == 45) and token_length > 0 and asciiAlpha(token[token_length - 1])) {
            if (token_length >= MAX_TOKEN_BYTES) return -1;
            token[token_length] = @intCast(byte);
            token_length += 1;
        } else {
            if (token_length > 0) {
                if (token[token_length - 1] == '-') token_length -= 1;
                if (token_length > 0) {
                    if (root < 0) {
                        if (used >= MAX_UNIQUE_WORDS) return -1;
                        root = @intCast(used);
                        @memcpy(nodes[used].word[0..token_length], token[0..token_length]);
                        nodes[used].word[token_length] = 0;
                        nodes[used].word_length = token_length;
                        nodes[used].frequency = 1;
                        used += 1;
                    } else {
                        var current: usize = @intCast(root);
                        while (true) {
                            const node_length = nodes[current].word_length;
                            const common = @min(token_length, node_length);
                            var order: i32 = 0;
                            for (0..common) |j| {
                                if (token[j] < nodes[current].word[j]) { order = -1; break; }
                                if (token[j] > nodes[current].word[j]) { order = 1; break; }
                            }
                            if (order == 0) {
                                if (token_length < node_length) {
                                    order = -1;
                                } else if (token_length > node_length) {
                                    order = 1;
                                }
                            }
                            if (order == 0) {
                                nodes[current].frequency += 1;
                                break;
                            }
                            const child = if (order < 0) nodes[current].left else nodes[current].right;
                            if (child < 0) {
                                if (used >= MAX_UNIQUE_WORDS) return -1;
                                const new_node = used;
                                @memcpy(nodes[new_node].word[0..token_length], token[0..token_length]);
                                nodes[new_node].word[token_length] = 0;
                                nodes[new_node].word_length = token_length;
                                nodes[new_node].frequency = 1;
                                if (order < 0) {
                                    nodes[current].left = @intCast(new_node);
                                } else {
                                    nodes[current].right = @intCast(new_node);
                                }
                                used += 1;
                                break;
                            }
                            current = @intCast(child);
                        }
                    }
                }
                token_length = 0;
            }
        }
    }

    var result: [MAX_OUTPUT_BYTES]u8 = undefined;
    var stack: [MAX_UNIQUE_WORDS]i32 = undefined;
    var top: usize = 0;
    var written: usize = 0;
    var current = root;
    while (current >= 0 or top > 0) {
        while (current >= 0) {
            if (top >= MAX_UNIQUE_WORDS) return -1;
            stack[top] = current;
            top += 1;
            current = nodes[@intCast(current)].left;
        }
        top -= 1;
        current = stack[top];
        const node_index: usize = @intCast(current);
        for (0..nodes[node_index].word_length) |i| {
            if (written >= MAX_OUTPUT_BYTES) return -1;
            result[written] = nodes[node_index].word[i];
            written += 1;
        }
        if (written + 1 >= MAX_OUTPUT_BYTES) return -1;
        result[written] = '\t';
        written += 1;
        var reversed: [20]u8 = undefined;
        var digits: usize = 0;
        var frequency = nodes[node_index].frequency;
        while (true) {
            reversed[digits] = '0' + @as(u8, @intCast(frequency % 10));
            digits += 1;
            frequency /= 10;
            if (frequency == 0) break;
        }
        while (digits > 0) {
            digits -= 1;
            if (written >= MAX_OUTPUT_BYTES) return -1;
            result[written] = reversed[digits];
            written += 1;
        }
        if (written >= MAX_OUTPUT_BYTES) return -1;
        result[written] = '\n';
        written += 1;
        current = nodes[node_index].right;
    }

    if (output == null or capacity < written) return -2;
    const output_ptr = output.?;
    for (0..written) |i| output_ptr[i] = result[i];
    return @intCast(written);
}
