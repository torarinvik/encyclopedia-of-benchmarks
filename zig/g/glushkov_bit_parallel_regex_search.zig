const MAX_TEXT: usize = 24;
const MAX_PATTERN: usize = 32;
const MAX_POSITIONS: usize = 8;
const MAX_NODES: usize = 64;

const NodeKind = enum(u8) { position = 1, concat = 2, alternate = 3, star = 4 };
const Node = struct { kind: NodeKind, left: usize = 0, right: usize = 0, position: usize = 0 };

const Parser = struct {
    pattern: [MAX_PATTERN]i64 = [_]i64{0} ** MAX_PATTERN,
    length: usize = 0,
    cursor: usize = 0,
    node_count: usize = 0,
    position_count: usize = 0,
    nodes: [MAX_NODES]Node = undefined,
    symbols: [MAX_POSITIONS + 1]u8 = [_]u8{0} ** (MAX_POSITIONS + 1),
    failed: bool = false,

    fn add(self: *Parser, kind: NodeKind, left: usize, right: usize, position: usize) usize {
        if (self.node_count >= MAX_NODES) { self.failed = true; return 0; }
        const result = self.node_count;
        self.node_count += 1;
        self.nodes[result] = .{ .kind = kind, .left = left, .right = right, .position = position };
        return result;
    }
    fn expression(self: *Parser) usize {
        var result = self.concatenation();
        while (!self.failed and self.cursor < self.length and self.pattern[self.cursor] == '|') {
            self.cursor += 1;
            const right = self.concatenation();
            result = self.add(.alternate, result, right, 0);
        }
        return result;
    }
    fn concatenation(self: *Parser) usize {
        if (self.cursor >= self.length or self.pattern[self.cursor] == '|' or self.pattern[self.cursor] == ')') {
            self.failed = true;
            return 0;
        }
        var result = self.repetition();
        while (!self.failed and self.cursor < self.length and self.pattern[self.cursor] != '|' and self.pattern[self.cursor] != ')') {
            const right = self.repetition();
            result = self.add(.concat, result, right, 0);
        }
        return result;
    }
    fn repetition(self: *Parser) usize {
        var result = self.atom();
        if (!self.failed and self.cursor < self.length and self.pattern[self.cursor] == '*') {
            self.cursor += 1;
            result = self.add(.star, result, 0, 0);
        }
        return result;
    }
    fn atom(self: *Parser) usize {
        if (self.cursor >= self.length) { self.failed = true; return 0; }
        const token = self.pattern[self.cursor];
        self.cursor += 1;
        if (token == '(') {
            const result = self.expression();
            if (self.failed or self.cursor >= self.length or self.pattern[self.cursor] != ')') {
                self.failed = true;
                return 0;
            }
            self.cursor += 1;
            return result;
        }
        if (token != 'a' and token != 'b' and token != 'c' and token != '.') { self.failed = true; return 0; }
        if (self.position_count >= MAX_POSITIONS) { self.failed = true; return 0; }
        self.position_count += 1;
        const position = self.position_count;
        self.symbols[position] = @intCast(token);
        return self.add(.position, 0, 0, position);
    }
};

export fn glushkov_bit_parallel_regex_search(input: ?[*]const i64, length: usize,
    output: ?[*]u8, capacity: usize) i64 {
    if (input == null or length < 2 or length > 58) return -1;
    const values = input.?;
    if (values[0] < 0 or values[0] > @as(i64, @intCast(MAX_TEXT)) or
        values[1] < 1 or values[1] > @as(i64, @intCast(MAX_PATTERN))) return -1;
    const text_len: usize = @intCast(values[0]);
    const pattern_len: usize = @intCast(values[1]);
    if (length != 2 + text_len + pattern_len) return -1;
    for (0..text_len + pattern_len) |i| if (values[2 + i] < 1 or values[2 + i] > 127) return -1;

    var parser = Parser{ .length = pattern_len };
    for (0..pattern_len) |i| parser.pattern[i] = values[2 + text_len + i];
    const root = parser.expression();
    if (parser.failed or parser.cursor != pattern_len or parser.node_count == 0) return -1;

    var nullable = [_]bool{false} ** MAX_NODES;
    var first = [_]u16{0} ** MAX_NODES;
    var last = [_]u16{0} ** MAX_NODES;
    var follow = [_]u16{0} ** (MAX_POSITIONS + 1);
    for (0..parser.node_count) |i| {
        const node = parser.nodes[i];
        switch (node.kind) {
            .position => {
                const bit: u16 = @as(u16, 1) << @intCast(node.position);
                first[i] = bit;
                last[i] = bit;
            },
            .star => {
                nullable[i] = true;
                first[i] = first[node.left];
                last[i] = last[node.left];
                for (1..parser.position_count + 1) |pos| {
                    const bit: u16 = @as(u16, 1) << @intCast(pos);
                    if (last[node.left] & bit != 0) follow[pos] |= first[node.left];
                }
            },
            .alternate => {
                nullable[i] = nullable[node.left] or nullable[node.right];
                first[i] = first[node.left] | first[node.right];
                last[i] = last[node.left] | last[node.right];
            },
            .concat => {
                nullable[i] = nullable[node.left] and nullable[node.right];
                first[i] = first[node.left] | (if (nullable[node.left]) first[node.right] else 0);
                last[i] = last[node.right] | (if (nullable[node.right]) last[node.left] else 0);
                for (1..parser.position_count + 1) |pos| {
                    const bit: u16 = @as(u16, 1) << @intCast(pos);
                    if (last[node.left] & bit != 0) follow[pos] |= first[node.right];
                }
            },
        }
    }
    follow[0] = first[root] | 1;
    var transitions = [_]u16{0} ** 512;
    const subset_count = @as(usize, 1) << @intCast(parser.position_count + 1);
    for (1..subset_count) |subset| {
        const state = @ctz(subset);
        transitions[subset] = transitions[subset & (subset - 1)] | follow[state];
    }
    var byte_masks = [_]u16{1} ** 128;
    for (1..parser.position_count + 1) |pos| {
        for (1..128) |byte| {
            if (parser.symbols[pos] == '.' or parser.symbols[pos] == byte) {
                byte_masks[byte] |= @as(u16, 1) << @intCast(pos);
            }
        }
    }
    var staged = [_]u8{0} ** MAX_TEXT;
    var active: u16 = 1;
    for (0..text_len) |i| {
        active = transitions[@intCast(active)] & byte_masks[@intCast(values[2 + i])];
        staged[i] = if (active & last[root] != 0) 1 else 0;
    }
    if (text_len != 0 and (output == null or capacity < text_len)) return -2;
    if (text_len != 0) @memcpy(output.?[0..text_len], staged[0..text_len]);
    return @intCast(text_len);
}
