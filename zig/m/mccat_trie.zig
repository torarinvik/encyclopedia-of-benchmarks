const MAX_WORDS: usize = 64;
const MAX_WORD_LENGTH: usize = 32;
const MAX_INPUT_VALUES: usize = 1 + MAX_WORDS * (1 + MAX_WORD_LENGTH);
const MAX_NODES: usize = MAX_WORDS * MAX_WORD_LENGTH;
const MAX_OUTPUT_BYTES: usize = MAX_WORDS * (MAX_WORD_LENGTH + 1);

const TrieNode = struct {
    value: u8 = 0,
    terminal: bool = false,
    postfix: usize = 0,
    other_char: usize = 0,
};

fn newNode(nodes: *[MAX_NODES + 1]TrieNode, used: *usize, value: u8) usize {
    used.* += 1;
    nodes[used.*].value = value;
    return used.*;
}

fn newSuffix(nodes: *[MAX_NODES + 1]TrieNode, used: *usize, values: []const i64,
             start: usize, wordLength: usize) usize {
    const root = newNode(nodes, used, @intCast(values[start]));
    var current = root;
    for (1..wordLength) |offset| {
        const child = newNode(nodes, used, @intCast(values[start + offset]));
        nodes[current].postfix = child;
        current = child;
    }
    nodes[current].terminal = true;
    return root;
}

fn insertWord(nodes: *[MAX_NODES + 1]TrieNode, used: *usize, current: usize,
              values: []const i64, start: usize, wordLength: usize, offset: usize) void {
    if (nodes[current].value == @as(u8, @intCast(values[start + offset]))) {
        if (offset + 1 == wordLength) {
            nodes[current].terminal = true;
        } else {
            const next = nodes[current].postfix;
            if (next == 0) {
                nodes[current].postfix = newSuffix(nodes, used, values, start + offset + 1, wordLength - offset - 1);
            } else {
                insertWord(nodes, used, next, values, start, wordLength, offset + 1);
            }
        }
    } else {
        const next = nodes[current].other_char;
        if (next == 0) {
            nodes[current].other_char = newSuffix(nodes, used, values, start + offset, wordLength - offset);
        } else {
            insertWord(nodes, used, next, values, start, wordLength, offset);
        }
    }
}

fn measureOutput(nodes: *const [MAX_NODES + 1]TrieNode, current: usize, depth: usize, outputLength: *usize) void {
    if (current == 0) return;
    if (nodes[current].terminal) outputLength.* += depth + 2;
    measureOutput(nodes, nodes[current].postfix, depth + 1, outputLength);
    measureOutput(nodes, nodes[current].other_char, depth, outputLength);
}

fn emitOutput(nodes: *const [MAX_NODES + 1]TrieNode, current: usize, depth: usize,
              prefix: *[MAX_WORD_LENGTH]u8, output: [*]u8, position: *usize) void {
    if (current == 0) return;
    prefix[depth] = nodes[current].value;
    if (nodes[current].terminal) {
        for (0..depth + 1) |index| {
            output[position.*] = prefix[index];
            position.* += 1;
        }
        output[position.*] = '\n';
        position.* += 1;
    }
    emitOutput(nodes, nodes[current].postfix, depth + 1, prefix, output, position);
    emitOutput(nodes, nodes[current].other_char, depth, prefix, output, position);
}

export fn mccat_trie(input: ?[*]const i64, length: usize, output: ?[*]u8, capacity: usize) i64 {
    if (input == null or length < 1 or length > MAX_INPUT_VALUES) return -1;
    const values = input.?[0..length];
    if (values[0] < 0 or values[0] > @as(i64, @intCast(MAX_WORDS))) return -1;
    const wordCount: usize = @intCast(values[0]);
    var starts: [MAX_WORDS]usize = undefined;
    var lengths: [MAX_WORDS]usize = undefined;
    var position: usize = 1;
    for (0..wordCount) |index| {
        if (position >= length) return -1;
        const wordLengthValue = values[position];
        position += 1;
        if (wordLengthValue < 1 or wordLengthValue > @as(i64, @intCast(MAX_WORD_LENGTH))) return -1;
        const wordLength: usize = @intCast(wordLengthValue);
        if (wordLength > length - position) return -1;
        starts[index] = position;
        lengths[index] = wordLength;
        for (0..wordLength) |offset| {
            if (values[position + offset] < 33 or values[position + offset] > 126) return -1;
        }
        position += wordLength;
    }
    if (position != length) return -1;

    var nodes: [MAX_NODES + 1]TrieNode = undefined;
    for (&nodes) |*node| node.* = .{};
    var used: usize = 0;
    var root: usize = 0;
    for (0..wordCount) |index| {
        if (root == 0) root = newSuffix(&nodes, &used, values, starts[index], lengths[index])
        else insertWord(&nodes, &used, root, values, starts[index], lengths[index], 0);
    }
    var outputLength: usize = 0;
    measureOutput(&nodes, root, 0, &outputLength);
    if (outputLength > MAX_OUTPUT_BYTES) return -1;
    if (outputLength != 0 and (output == null or capacity < outputLength)) return -2;
    if (outputLength == 0) return 0;
    var prefix: [MAX_WORD_LENGTH]u8 = undefined;
    var written: usize = 0;
    emitOutput(&nodes, root, 0, &prefix, output.?, &written);
    return @intCast(written);
}
