const MAX_STRINGS: usize = 16;
const MAX_STRING_LENGTH: usize = 8;
const MAX_INPUT_WORDS: usize = 145;
const MAX_TRIE_NODES: usize = 129;
const BUCKET_THRESHOLD: usize = 3;

const BurstNode = struct {
    depth: usize,
    burst: bool,
    children: [4]usize,
    bucket: [MAX_STRINGS]usize,
    bucket_count: usize,
    terminal: [MAX_STRINGS]usize,
    terminal_count: usize,

    fn empty(depth: usize) BurstNode {
        return .{
            .depth = depth,
            .burst = false,
            .children = .{ MAX_TRIE_NODES, MAX_TRIE_NODES, MAX_TRIE_NODES, MAX_TRIE_NODES },
            .bucket = [_]usize{0} ** MAX_STRINGS,
            .bucket_count = 0,
            .terminal = [_]usize{0} ** MAX_STRINGS,
            .terminal_count = 0,
        };
    }
};

const BurstState = struct {
    nodes: [MAX_TRIE_NODES]BurstNode,
    node_count: usize,
    lengths: [MAX_STRINGS]usize,
    bytes: [[MAX_STRING_LENGTH]u8; MAX_STRINGS],

    fn init() BurstState {
        var state: BurstState = undefined;
        state.node_count = 0;
        state.lengths = [_]usize{0} ** MAX_STRINGS;
        state.bytes = [_][MAX_STRING_LENGTH]u8{[_]u8{0} ** MAX_STRING_LENGTH} ** MAX_STRINGS;
        for (&state.nodes) |*node| node.* = BurstNode.empty(0);
        return state;
    }

    fn newNode(self: *BurstState, depth: usize) usize {
        if (self.node_count >= MAX_TRIE_NODES) return MAX_TRIE_NODES;
        const node = self.node_count;
        self.node_count += 1;
        self.nodes[node] = BurstNode.empty(depth);
        return node;
    }

    fn addToChild(self: *BurstState, node: usize, string_id: usize) bool {
        const depth = self.nodes[node].depth;
        const symbol: usize = self.bytes[string_id][depth];
        var child = self.nodes[node].children[symbol];
        if (child == MAX_TRIE_NODES) {
            child = self.newNode(depth + 1);
            if (child == MAX_TRIE_NODES) return false;
            self.nodes[node].children[symbol] = child;
        }
        return self.addString(child, string_id);
    }

    fn addString(self: *BurstState, node: usize, string_id: usize) bool {
        const depth = self.nodes[node].depth;
        if (self.lengths[string_id] == depth) {
            const terminal_count = self.nodes[node].terminal_count;
            if (terminal_count >= MAX_STRINGS) return false;
            self.nodes[node].terminal[terminal_count] = string_id;
            self.nodes[node].terminal_count = terminal_count + 1;
            return true;
        }
        if (self.nodes[node].burst) return self.addToChild(node, string_id);

        const bucket_count = self.nodes[node].bucket_count;
        if (bucket_count < BUCKET_THRESHOLD) {
            self.nodes[node].bucket[bucket_count] = string_id;
            self.nodes[node].bucket_count = bucket_count + 1;
            return true;
        }

        var pending = [_]usize{0} ** MAX_STRINGS;
        for (0..bucket_count) |index| pending[index] = self.nodes[node].bucket[index];
        self.nodes[node].bucket_count = 0;
        self.nodes[node].burst = true;
        for (0..bucket_count) |index| {
            if (!self.addToChild(node, pending[index])) return false;
        }
        return self.addToChild(node, string_id);
    }

    fn lessStrings(self: *const BurstState, left: usize, right: usize) bool {
        const left_length = self.lengths[left];
        const right_length = self.lengths[right];
        const common_length = if (left_length < right_length) left_length else right_length;
        for (0..common_length) |index| {
            if (self.bytes[left][index] != self.bytes[right][index]) {
                return self.bytes[left][index] < self.bytes[right][index];
            }
        }
        return left_length < right_length;
    }

    fn keyCode(self: *const BurstState, string_id: usize) i64 {
        var code: i64 = 0;
        var weight: i64 = 78_125; // 5^(7-j), j is measured from the string's first byte.
        for (0..self.lengths[string_id]) |index| {
            code += (@as(i64, self.bytes[string_id][index]) + 1) * weight;
            weight /= 5;
        }
        return code;
    }

    fn emitNode(self: *BurstState, node: usize, rank: *i64, checksum: *i64) void {
        const terminal_count = self.nodes[node].terminal_count;
        for (0..terminal_count) |index| {
            rank.* += 1;
            checksum.* += rank.* * self.keyCode(self.nodes[node].terminal[index]);
        }
        if (self.nodes[node].burst) {
            for (0..4) |symbol| {
                const child = self.nodes[node].children[symbol];
                if (child != MAX_TRIE_NODES) self.emitNode(child, rank, checksum);
            }
            return;
        }

        const bucket_count = self.nodes[node].bucket_count;
        if (bucket_count > 1) {
            for (1..bucket_count) |position| {
                const item = self.nodes[node].bucket[position];
                var insertion = position;
                while (insertion > 0 and self.lessStrings(item, self.nodes[node].bucket[insertion - 1])) : (insertion -= 1) {
                    self.nodes[node].bucket[insertion] = self.nodes[node].bucket[insertion - 1];
                }
                self.nodes[node].bucket[insertion] = item;
            }
        }
        for (0..bucket_count) |index| {
            rank.* += 1;
            checksum.* += rank.* * self.keyCode(self.nodes[node].bucket[index]);
        }
    }
};

export fn burstsort(input_opt: ?[*]const i64, length: usize) i64 {
    if (input_opt == null or length < 1 or length > MAX_INPUT_WORDS) return -1;
    const input = input_opt.?;
    const string_count_value = input[0];
    if (string_count_value < 0 or string_count_value > 16) return -1;
    const string_count: usize = @intCast(string_count_value);

    var state = BurstState.init();
    var position: usize = 1;
    for (0..string_count) |string_id| {
        if (position >= length) return -1;
        const string_length_value = input[position];
        position += 1;
        if (string_length_value < 0 or string_length_value > 8) return -1;
        const string_length: usize = @intCast(string_length_value);
        if (string_length > length - position) return -1;
        state.lengths[string_id] = string_length;
        for (0..string_length) |byte_index| {
            const byte = input[position];
            position += 1;
            if (byte < 0 or byte > 3) return -1;
            state.bytes[string_id][byte_index] = @intCast(byte);
        }
    }
    if (position != length) return -1;

    const root = state.newNode(0);
    if (root == MAX_TRIE_NODES) return -1;
    for (0..string_count) |string_id| {
        if (!state.addString(root, string_id)) return -1;
    }
    var rank: i64 = 0;
    var checksum: i64 = 0;
    state.emitNode(root, &rank, &checksum);
    return checksum;
}
