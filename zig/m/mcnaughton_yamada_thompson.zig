const MAX_PATTERN_LENGTH: usize = 16;
const MAX_TEXT_LENGTH: usize = 32;
const MAX_INPUT_LENGTH: usize = 51;
const MAX_AST_NODES: usize = 32;
const MAX_NFA_STATES: usize = 8;
const MAX_NFA_EDGES: usize = 32;

const EMPTY: u8 = 0;
const LITERAL: u8 = 1;
const CONCAT: u8 = 2;
const UNION: u8 = 3;
const STAR: u8 = 4;

const Node = struct {
    kind: u8 = 0,
    value: u8 = 0,
    left: usize = 0,
    right: usize = 0,
};

const Parser = struct {
    pattern: [MAX_PATTERN_LENGTH]u8,
    length: usize,
    position: usize = 0,
    nodes: [MAX_AST_NODES]Node = @splat(.{}),
    node_count: usize = 0,
    fragments: usize = 0,

    fn addNode(self: *Parser, kind: u8, value: u8, left: usize, right: usize) ?usize {
        if (self.node_count >= MAX_AST_NODES) return null;
        const index = self.node_count;
        self.nodes[index] = .{ .kind = kind, .value = value, .left = left, .right = right };
        self.node_count += 1;
        if (kind == LITERAL or kind == UNION or kind == STAR) self.fragments += 1;
        return index;
    }

    fn peek(self: *const Parser) ?u8 {
        if (self.position < self.length) return self.pattern[self.position];
        return null;
    }

    fn parseUnion(self: *Parser) ?usize {
        var node = self.parseConcat() orelse return null;
        while (self.peek()) |token| {
            if (token != '|') break;
            self.position += 1;
            const right = self.parseConcat() orelse return null;
            node = self.addNode(UNION, 0, node, right) orelse return null;
        }
        return node;
    }

    fn parseConcat(self: *Parser) ?usize {
        const first = self.peek() orelse return null;
        if (first == ')' or first == '|') return null;
        var node = self.parseRepeat() orelse return null;
        while (self.peek()) |token| {
            if (token == ')' or token == '|') break;
            const right = self.parseRepeat() orelse return null;
            node = self.addNode(CONCAT, 0, node, right) orelse return null;
        }
        return node;
    }

    fn parseRepeat(self: *Parser) ?usize {
        var node = self.parseAtom() orelse return null;
        if (self.peek()) |token| {
            if (token == '*') {
                self.position += 1;
                node = self.addNode(STAR, 0, node, 0) orelse return null;
            }
        }
        return node;
    }

    fn parseAtom(self: *Parser) ?usize {
        const token = self.peek() orelse return null;
        if (token == 'a' or token == 'b' or token == 'c') {
            self.position += 1;
            return self.addNode(LITERAL, token, 0, 0);
        }
        if (token == '(') {
            self.position += 1;
            const node = self.parseUnion() orelse return null;
            if (self.peek() == null or self.peek().? != ')') return null;
            self.position += 1;
            return node;
        }
        return null;
    }
};

fn isLiteral(token: u8) bool {
    return token != '(' and token != ')' and token != '*' and token != '|' and token != '\n';
}

fn sourceSubstringCompatible(source: []const u8) bool {
    if (source.len <= 1) return true;
    if (source[0] == '(' and source[source.len - 1] == ')') {
        var depth: i32 = 0;
        for (source, 0..) |token, index| {
            if (token == '(') depth += 1;
            if (token == ')') depth -= 1;
            if (depth == 0 and index + 1 < source.len) return false;
        }
        if (depth != 0) return false;
        return sourceSubstringCompatible(source[1 .. source.len - 1]);
    }
    for ([_]u8{ '|', '\n' }) |operator| {
        var depth: i32 = 0;
        for (source, 0..) |token, index| {
            if (depth == 0 and token == operator) {
                return sourceSubstringCompatible(source[0..index]) and
                    sourceSubstringCompatible(source[index + 1 ..]);
            }
            if (token == '(') depth += 1;
            if (token == ')') depth -= 1;
        }
    }
    return source[source.len - 1] == '*' and sourceSubstringCompatible(source[0 .. source.len - 1]);
}

fn sourceCompatible(pattern: []const u8) bool {
    var preprocessed: [2 * MAX_PATTERN_LENGTH]u8 = @splat(0);
    var length: usize = 0;
    for (pattern, 0..) |token, index| {
        preprocessed[length] = token;
        length += 1;
        if (index + 1 == pattern.len) continue;
        const next = pattern[index + 1];
        if ((isLiteral(token) and isLiteral(next)) or (isLiteral(token) and next == '(') or
            (token == ')' and next == '(') or (token == ')' and isLiteral(next)) or
            (token == '*' and isLiteral(next)) or (token == '*' and next == '('))
        {
            preprocessed[length] = '\n';
            length += 1;
        }
    }
    return sourceSubstringCompatible(preprocessed[0..length]);
}

const Edge = struct { from: u8 = 0, to: u8 = 0, label: u8 = 0 };
const Fragment = struct { start: usize, accept: usize };

const Nfa = struct {
    state_count: usize = 0,
    edge_count: usize = 0,
    edges: [MAX_NFA_EDGES]Edge = @splat(.{}),

    fn addState(self: *Nfa) ?usize {
        if (self.state_count >= MAX_NFA_STATES) return null;
        const state = self.state_count;
        self.state_count += 1;
        return state;
    }

    fn addEdge(self: *Nfa, from: usize, to: usize, label: u8) bool {
        if (self.edge_count >= MAX_NFA_EDGES) return false;
        self.edges[self.edge_count] = .{ .from = @intCast(from), .to = @intCast(to), .label = label };
        self.edge_count += 1;
        return true;
    }
};

fn compile(node_index: usize, nodes: []const Node, nfa: *Nfa) ?Fragment {
    const node = nodes[node_index];
    switch (node.kind) {
        EMPTY => {
            const start = nfa.addState() orelse return null;
            const accept = nfa.addState() orelse return null;
            if (!nfa.addEdge(start, accept, 0)) return null;
            return .{ .start = start, .accept = accept };
        },
        LITERAL => {
            const start = nfa.addState() orelse return null;
            const accept = nfa.addState() orelse return null;
            if (!nfa.addEdge(start, accept, node.value)) return null;
            return .{ .start = start, .accept = accept };
        },
        CONCAT => {
            const left = compile(node.left, nodes, nfa) orelse return null;
            const right = compile(node.right, nodes, nfa) orelse return null;
            if (!nfa.addEdge(left.accept, right.start, 0)) return null;
            return .{ .start = left.start, .accept = right.accept };
        },
        UNION => {
            const left = compile(node.left, nodes, nfa) orelse return null;
            const right = compile(node.right, nodes, nfa) orelse return null;
            const start = nfa.addState() orelse return null;
            const accept = nfa.addState() orelse return null;
            if (!nfa.addEdge(start, left.start, 0) or !nfa.addEdge(start, right.start, 0) or
                !nfa.addEdge(left.accept, accept, 0) or !nfa.addEdge(right.accept, accept, 0)) return null;
            return .{ .start = start, .accept = accept };
        },
        STAR => {
            const child = compile(node.left, nodes, nfa) orelse return null;
            const start = nfa.addState() orelse return null;
            const accept = nfa.addState() orelse return null;
            if (!nfa.addEdge(start, child.start, 0) or !nfa.addEdge(start, accept, 0) or
                !nfa.addEdge(child.accept, child.start, 0) or !nfa.addEdge(child.accept, accept, 0)) return null;
            return .{ .start = start, .accept = accept };
        },
        else => return null,
    }
}

fn epsilonClosure(initial: u16, nfa: *const Nfa) u16 {
    var states = initial;
    while (true) {
        const before = states;
        for (nfa.edges[0..nfa.edge_count]) |edge| {
            if (edge.label == 0 and (states & (@as(u16, 1) << edge.from)) != 0) {
                states |= @as(u16, 1) << edge.to;
            }
        }
        if (states == before) return states;
    }
}

export fn mcnaughton_yamada_thompson(input: ?[*]const i64, input_length: usize) i64 {
    if (input == null or input_length < 2 or input_length > MAX_INPUT_LENGTH) return -1;
    const values = input.?[0..input_length];
    if (values[0] < 0 or values[0] > @as(i64, @intCast(MAX_PATTERN_LENGTH)) or
        values[1] < 0 or values[1] > @as(i64, @intCast(MAX_TEXT_LENGTH))) return -1;
    const pattern_length: usize = @intCast(values[0]);
    const text_length: usize = @intCast(values[1]);
    if (input_length != 2 + pattern_length + text_length) return -1;

    var pattern: [MAX_PATTERN_LENGTH]u8 = @splat(0);
    for (0..pattern_length) |index| {
        const value = values[2 + index];
        if (value != 97 and value != 98 and value != 99 and value != 40 and value != 41 and value != 42 and value != 124) return -1;
        pattern[index] = @intCast(value);
    }
    const pattern_slice = pattern[0..pattern_length];
    const text_start = 2 + pattern_length;
    for (0..text_length) |index| {
        if (values[text_start + index] < 1 or values[text_start + index] > 127) return -1;
    }
    if (!sourceCompatible(pattern_slice)) return -1;

    var parser = Parser{ .pattern = pattern, .length = pattern_length };
    const root = if (pattern_length == 0) parser.addNode(EMPTY, 0, 0, 0) else parser.parseUnion();
    if (root == null or parser.position != parser.length or parser.fragments > 4) return -1;

    var nfa = Nfa{};
    const fragment = compile(root.?, parser.nodes[0..parser.node_count], &nfa) orelse return -1;
    var active = epsilonClosure(@as(u16, 1) << @intCast(fragment.start), &nfa);
    for (0..text_length) |index| {
        const symbol: u8 = @intCast(values[text_start + index]);
        var next: u16 = 0;
        for (nfa.edges[0..nfa.edge_count]) |edge| {
            if (edge.label == symbol and (active & (@as(u16, 1) << edge.from)) != 0) {
                next |= @as(u16, 1) << edge.to;
            }
        }
        active = epsilonClosure(next, &nfa);
    }
    return if ((active & (@as(u16, 1) << @intCast(fragment.accept))) != 0) 1 else 0;
}
