const MAX_TEXT_LENGTH: usize = 64;
const MAX_INPUT_LENGTH: usize = 66;
const MAX_SYMBOLS: usize = MAX_TEXT_LENGTH + 1;
const MAX_NODES: usize = 130;

const SuffixNode = struct {
    edge_start: usize,
    edge_end: usize,
    suffix_link: usize,
    suffix_start: usize,
    leaf: bool,
    children: [5]usize,

    fn empty() SuffixNode {
        return .{
            .edge_start = 0,
            .edge_end = 0,
            .suffix_link = 0,
            .suffix_start = 0,
            .leaf = false,
            .children = .{ MAX_NODES, MAX_NODES, MAX_NODES, MAX_NODES, MAX_NODES },
        };
    }
};

const Accumulator = struct {
    rank: i64 = 0,
    checksum: i64 = 0,
    distinct_substrings: i64 = 0,

    fn pushToken(self: *Accumulator, token: i64) void {
        self.rank += 1;
        self.checksum += self.rank * token;
    }
};

const UkkonenState = struct {
    symbols: [MAX_SYMBOLS]usize,
    symbol_count: usize,
    leaf_end: usize,
    nodes: [MAX_NODES]SuffixNode,
    node_count: usize,

    fn init() UkkonenState {
        var state: UkkonenState = undefined;
        state.symbols = [_]usize{0} ** MAX_SYMBOLS;
        state.symbol_count = 0;
        state.leaf_end = 0;
        state.node_count = 0;
        for (&state.nodes) |*node| node.* = SuffixNode.empty();
        return state;
    }

    fn newNode(self: *UkkonenState, edge_start: usize, edge_end: usize, leaf: bool, suffix_start: usize) usize {
        if (self.node_count >= MAX_NODES) return MAX_NODES;
        const node = self.node_count;
        self.node_count += 1;
        self.nodes[node] = SuffixNode.empty();
        self.nodes[node].edge_start = edge_start;
        self.nodes[node].edge_end = edge_end;
        self.nodes[node].leaf = leaf;
        self.nodes[node].suffix_start = suffix_start;
        return node;
    }

    fn edgeLength(self: *const UkkonenState, node: usize) usize {
        const end = if (self.nodes[node].leaf) self.leaf_end + 1 else self.nodes[node].edge_end;
        return end - self.nodes[node].edge_start;
    }

    fn buildOnlineTree(self: *UkkonenState) bool {
        const root = self.newNode(0, 0, false, 0);
        if (root != 0) return false;
        self.nodes[root].suffix_link = root;

        var active_node = root;
        var active_edge: usize = 0;
        var active_length: usize = 0;
        var remaining: usize = 0;
        self.leaf_end = 0;

        for (0..self.symbol_count) |position| {
            self.leaf_end = position;
            remaining += 1;
            var last_internal: usize = MAX_NODES;

            while (remaining > 0) {
                if (active_length == 0) active_edge = position;
                const active_symbol = self.symbols[active_edge];
                var next = self.nodes[active_node].children[active_symbol];

                if (next == MAX_NODES) {
                    const suffix_start = position - remaining + 1;
                    next = self.newNode(position, 0, true, suffix_start);
                    if (next == MAX_NODES) return false;
                    self.nodes[active_node].children[active_symbol] = next;
                    if (last_internal != MAX_NODES) {
                        self.nodes[last_internal].suffix_link = active_node;
                        last_internal = MAX_NODES;
                    }
                } else {
                    const next_length = self.edgeLength(next);
                    if (active_length >= next_length) {
                        active_edge += next_length;
                        active_length -= next_length;
                        active_node = next;
                        continue;
                    }

                    const next_start = self.nodes[next].edge_start;
                    if (self.symbols[next_start + active_length] == self.symbols[position]) {
                        if (last_internal != MAX_NODES and active_node != root) {
                            self.nodes[last_internal].suffix_link = active_node;
                            last_internal = MAX_NODES;
                        }
                        active_length += 1;
                        break;
                    }

                    const split = self.newNode(next_start, next_start + active_length, false, 0);
                    if (split == MAX_NODES) return false;
                    self.nodes[active_node].children[active_symbol] = split;
                    self.nodes[next].edge_start += active_length;
                    const old_symbol = self.symbols[self.nodes[next].edge_start];
                    self.nodes[split].children[old_symbol] = next;

                    const suffix_start = position - remaining + 1;
                    const leaf = self.newNode(position, 0, true, suffix_start);
                    if (leaf == MAX_NODES) return false;
                    self.nodes[split].children[self.symbols[position]] = leaf;
                    if (last_internal != MAX_NODES) self.nodes[last_internal].suffix_link = split;
                    last_internal = split;
                }

                remaining -= 1;
                if (active_node == root and active_length > 0) {
                    active_length -= 1;
                    active_edge = position - remaining + 1;
                } else if (active_node != root) {
                    active_node = self.nodes[active_node].suffix_link;
                }
            }
        }
        return true;
    }

    fn emitNode(self: *const UkkonenState, node: usize, is_root: bool, accumulator: *Accumulator) void {
        if (is_root) accumulator.pushToken(0);
        for (0..5) |symbol| {
            const child = self.nodes[node].children[symbol];
            if (child == MAX_NODES) continue;
            const edge_end = if (self.nodes[child].leaf) self.leaf_end + 1 else self.nodes[child].edge_end;
            const edge_start = self.nodes[child].edge_start;
            accumulator.pushToken(1);
            accumulator.pushToken(@intCast(edge_end - edge_start));
            for (edge_start..edge_end) |index| {
                const value = self.symbols[index];
                accumulator.pushToken(@intCast(value + 1));
                if (value != 4) accumulator.distinct_substrings += 1;
            }
            if (self.nodes[child].leaf) {
                accumulator.pushToken(2);
                accumulator.pushToken(@intCast(self.nodes[child].suffix_start + 1));
            } else {
                accumulator.pushToken(3);
                self.emitNode(child, false, accumulator);
                accumulator.pushToken(4);
            }
        }
        if (is_root) accumulator.pushToken(4);
    }
};

export fn ukkonen_suffix_tree(input_opt: ?[*]const i64, length: usize) i64 {
    if (input_opt == null or length < 1 or length > MAX_INPUT_LENGTH) return -1;
    const input = input_opt.?;
    const text_length_value = input[0];
    if (text_length_value < 0 or text_length_value > 64) return -1;
    const text_length: usize = @intCast(text_length_value);
    if (length != text_length + 1) return -1;

    var state = UkkonenState.init();
    for (0..text_length) |index| {
        const symbol = input[index + 1];
        if (symbol < 0 or symbol > 3) return -1;
        state.symbols[index] = @intCast(symbol);
    }
    state.symbols[text_length] = 4;
    state.symbol_count = text_length + 1;
    if (!state.buildOnlineTree()) return -1;

    var accumulator = Accumulator{};
    state.emitNode(0, true, &accumulator);
    return (@as(i64, @intCast(state.node_count)) << 44)
        + (accumulator.distinct_substrings << 32)
        + accumulator.checksum;
}
