const MAX_TEXT: usize = 64;
const MAX_NODES: usize = MAX_TEXT + 2;
const ALPHABET: usize = 4;
const MAX_WORDS: usize = MAX_TEXT + 1;

const Node = struct {
    length: i32 = 0,
    suffix_link: usize = 1,
    difference: i32 = 0,
    series_link: usize = 1,
    series_best: i32 = 0,
    series_start: usize = 0,
    next: [ALPHABET]usize = @splat(0),
};

fn findExtendable(nodes: *const [MAX_NODES]Node, text: []const usize,
    position: usize, start: usize) usize {
    var node = start;
    while (true) {
        const preceding = @as(i64, @intCast(position)) - 1 - @as(i64, nodes[node].length);
        if (preceding >= 0 and text[@intCast(preceding)] == text[position]) return node;
        node = nodes[node].suffix_link;
    }
}

fn putI64(output: [*]u8, offset: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |byte| {
        const shift: u6 = @intCast(byte * 8);
        output[offset + byte] = @truncate(bits >> shift);
    }
}

export fn palindromic_partition_series_links(
    input_opt: ?[*]const i64,
    length: usize,
    output_opt: ?[*]u8,
    capacity: usize,
) i64 {
    const input = input_opt orelse return -1;
    if (length < 1 or length > MAX_TEXT + 2) return -1;
    if (input[0] < 0 or input[0] > MAX_TEXT) return -1;
    const n: usize = @intCast(input[0]);
    if (length != n + 1) return -1;
    var text: [MAX_TEXT]usize = @splat(0);
    for (0..n) |position| {
        if (input[position + 1] < 0 or input[position + 1] >= ALPHABET) return -1;
        text[position] = @intCast(input[position + 1]);
    }

    var nodes: [MAX_NODES]Node = @splat(.{});
    nodes[0].length = 0;
    nodes[0].suffix_link = 1;
    nodes[1].length = -1;
    nodes[1].suffix_link = 1;
    var node_count: usize = 2;
    var last: usize = 0;
    var dp: [MAX_TEXT + 1]i32 = @splat(MAX_TEXT + 1);
    var predecessor: [MAX_TEXT + 1]usize = @splat(0);
    dp[0] = 0;

    for (0..n) |position| {
        const end = position + 1;
        const symbol = text[position];
        const parent = findExtendable(&nodes, text[0..n], position, last);
        var next = nodes[parent].next[symbol];
        if (next == 0) {
            next = node_count;
            node_count += 1;
            nodes[next].length = nodes[parent].length + 2;
            nodes[parent].next[symbol] = next;
            if (nodes[next].length == 1) {
                nodes[next].suffix_link = 0;
            } else {
                const suffix_parent = findExtendable(
                    &nodes, text[0..n], position, nodes[parent].suffix_link,
                );
                nodes[next].suffix_link = nodes[suffix_parent].next[symbol];
            }
            const fail = nodes[next].suffix_link;
            nodes[next].difference = nodes[next].length - nodes[fail].length;
            if (nodes[next].difference == nodes[fail].difference) {
                nodes[next].series_link = nodes[fail].series_link;
            } else {
                nodes[next].series_link = fail;
            }
        }
        last = next;

        var best_value: i32 = MAX_TEXT + 1;
        var best_start = end;
        var node = last;
        while (nodes[node].length > 0) {
            const start_value = @as(i64, @intCast(end)) -
                @as(i64, nodes[nodes[node].series_link].length) -
                @as(i64, nodes[node].difference);
            const start: usize = @intCast(start_value);
            nodes[node].series_best = dp[start];
            nodes[node].series_start = start;
            const fail = nodes[node].suffix_link;
            if (nodes[node].difference == nodes[fail].difference and
                (nodes[fail].series_best < nodes[node].series_best or
                 (nodes[fail].series_best == nodes[node].series_best and
                  nodes[fail].series_start < nodes[node].series_start))) {
                nodes[node].series_best = nodes[fail].series_best;
                nodes[node].series_start = nodes[fail].series_start;
            }
            const candidate = nodes[node].series_best + 1;
            if (candidate < best_value or
                (candidate == best_value and nodes[node].series_start < best_start)) {
                best_value = candidate;
                best_start = nodes[node].series_start;
            }
            node = nodes[node].series_link;
        }
        dp[end] = best_value;
        predecessor[end] = best_start;
    }

    var reverse_pieces: [MAX_TEXT]usize = @splat(0);
    var piece_count: usize = 0;
    var end = n;
    while (end > 0) {
        reverse_pieces[piece_count] = end - predecessor[end];
        piece_count += 1;
        end = predecessor[end];
    }
    var words: [MAX_WORDS]i64 = @splat(0);
    var word_count: usize = 0;
    words[word_count] = @intCast(piece_count);
    word_count += 1;
    for (0..piece_count) |index| {
        words[word_count] = @intCast(reverse_pieces[piece_count - 1 - index]);
        word_count += 1;
    }
    const bytes = word_count * 8;
    const output = output_opt orelse return -2;
    if (capacity < bytes) return -2;
    for (0..word_count) |word| putI64(output, word * 8, words[word]);
    return @intCast(bytes);
}
