const MIN_STRINGS: i64 = 2;
const MAX_STRINGS: usize = 8;
const MAX_TOTAL_SYMBOLS: usize = 24;
const MAX_TRIE_NODES: usize = MAX_TOTAL_SYMBOLS + 1;
const MAX_STATES: usize = 49;
const ALPHABET_SIZE: usize = 4;
const MAX_PARSEABLE_LENGTH: usize = 34;

const GsaState = struct {
    length: usize,
    link: i32,
    next: [ALPHABET_SIZE]usize,
};

export fn generalized_suffix_automaton_union(input_opt: ?[*]const i64, length: usize) i64 {
    if (input_opt == null or length < 1 or length > MAX_PARSEABLE_LENGTH) return -1;
    const input = input_opt.?;
    const string_count_value = input[0];
    if (string_count_value < MIN_STRINGS or string_count_value > 8) return -1;
    const string_count: usize = @intCast(string_count_value);

    var states: [MAX_STATES]GsaState = undefined;
    for (0..MAX_STATES) |state| {
        states[state] = .{ .length = 0, .link = -1, .next = [_]usize{0} ** ALPHABET_SIZE };
    }
    var trie_next: [MAX_TRIE_NODES][ALPHABET_SIZE]usize = undefined;
    for (0..MAX_TRIE_NODES) |node| trie_next[node] = [_]usize{0} ** ALPHABET_SIZE;
    var trie_parent = [_]usize{0} ** MAX_TRIE_NODES;
    var trie_symbol = [_]usize{0} ** MAX_TRIE_NODES;
    var trie_node_count: usize = 1;
    var total_symbols: usize = 0;
    var cursor: usize = 1;

    for (0..string_count) |_| {
        if (cursor >= length) return -1;
        const string_length_value = input[cursor];
        cursor += 1;
        if (string_length_value < 0 or string_length_value > 8) return -1;
        const string_length: usize = @intCast(string_length_value);
        if (total_symbols + string_length > MAX_TOTAL_SYMBOLS or string_length > length - cursor) return -1;
        total_symbols += string_length;

        var node: usize = 0;
        for (0..string_length) |offset| {
            const symbol_value = input[cursor + offset];
            if (symbol_value < 0 or symbol_value > 3) return -1;
            const symbol: usize = @intCast(symbol_value);
            var child = trie_next[node][symbol];
            if (child == 0) {
                if (trie_node_count >= MAX_TRIE_NODES) return -1;
                child = trie_node_count;
                trie_node_count += 1;
                trie_next[node][symbol] = child;
                states[node].next[symbol] = child;
                trie_parent[child] = node;
                trie_symbol[child] = symbol;
            }
            node = child;
        }
        cursor += string_length;
    }
    if (cursor != length) return -1;

    var state_count = trie_node_count;
    var queue = [_]usize{0} ** MAX_TRIE_NODES;
    var queue_head: usize = 0;
    var queue_tail: usize = 0;
    for (0..ALPHABET_SIZE) |symbol| {
        const child = trie_next[0][symbol];
        if (child != 0) {
            queue[queue_tail] = child;
            queue_tail += 1;
        }
    }

    while (queue_head < queue_tail) {
        const current = queue[queue_head];
        queue_head += 1;
        const parent = trie_parent[current];
        const symbol = trie_symbol[current];
        states[current].length = states[parent].length + 1;

        var previous = states[parent].link;
        while (previous != -1 and states[@intCast(previous)].next[symbol] == 0) {
            states[@intCast(previous)].next[symbol] = current;
            previous = states[@intCast(previous)].link;
        }
        if (previous == -1) {
            states[current].link = 0;
        } else {
            const next_state = states[@intCast(previous)].next[symbol];
            if (states[@intCast(previous)].length + 1 == states[next_state].length) {
                states[current].link = @intCast(next_state);
            } else {
                if (state_count >= MAX_STATES) return -1;
                const clone = state_count;
                state_count += 1;
                states[clone].length = states[@intCast(previous)].length + 1;
                states[clone].link = states[next_state].link;
                for (0..ALPHABET_SIZE) |character| {
                    const destination = states[next_state].next[character];
                    if (destination != 0 and states[destination].length > 0) {
                        states[clone].next[character] = destination;
                    }
                }
                while (previous != -1 and states[@intCast(previous)].next[symbol] == next_state) {
                    states[@intCast(previous)].next[symbol] = clone;
                    previous = states[@intCast(previous)].link;
                }
                states[next_state].link = @intCast(clone);
                states[current].link = @intCast(clone);
            }
        }

        for (0..ALPHABET_SIZE) |character| {
            const child = trie_next[current][character];
            if (child != 0) {
                queue[queue_tail] = child;
                queue_tail += 1;
            }
        }
    }

    var distinct_count: i64 = 0;
    for (1..state_count) |state| {
        const link: usize = @intCast(states[state].link);
        distinct_count += @intCast(states[state].length - states[link].length);
    }
    return distinct_count;
}
