const max_text: usize = 12;
const max_pattern: usize = 8;
const max_sigma: usize = 4;
const max_suffixes: usize = max_text + 1;
const max_nodes: usize = 2 * max_suffixes - 1;
const max_input: usize = 24;
const max_output: usize = 16;

const Node = struct {
    edge_start: usize,
    edge_length: usize,
    depth: usize,
    leaf_start: i32,
    child: [5]i32,
    leaf_count: usize,
    sa_left: usize,
    sa_right: usize,
    sigma: bool,
    kind: u8,
    sigma_child_count: usize,
    sigma_child: [5]i32,
    child_by_symbol: [max_sigma]i32,
    group_by_symbol: [max_sigma]i32,
    gap_count: usize,
    gap_left: [5]i32,
    gap_right: [5]i32,
    separator: i8,
    only_sigma_child: i32,
    left_valid: bool,
    left_interval: [2]i32,
    right_valid: bool,
    right_interval: [2]i32,

    fn empty() Node {
        return .{
            .edge_start = 0,
            .edge_length = 0,
            .depth = 0,
            .leaf_start = -1,
            .child = @splat(-1),
            .leaf_count = 0,
            .sa_left = 0,
            .sa_right = 0,
            .sigma = false,
            .kind = 0,
            .sigma_child_count = 0,
            .sigma_child = @splat(-1),
            .child_by_symbol = @splat(-1),
            .group_by_symbol = @splat(-1),
            .gap_count = 0,
            .gap_left = @splat(-1),
            .gap_right = @splat(-1),
            .separator = -2,
            .only_sigma_child = -1,
            .left_valid = false,
            .left_interval = @splat(-1),
            .right_valid = false,
            .right_interval = @splat(-1),
        };
    }
};

const SuffixOrder = struct {
    sa: [max_suffixes]usize,
    rank: [max_suffixes]usize,
};

fn slot(symbol: i8) usize {
    return @intCast(symbol + 1);
}

fn suffixCompare(text: []const i8, length: usize, a: usize, b: usize) i32 {
    var offset: usize = 0;
    while (a + offset < length and b + offset < length) : (offset += 1) {
        if (text[a + offset] != text[b + offset]) {
            return if (text[a + offset] < text[b + offset]) -1 else 1;
        }
    }
    if (a + offset == length and b + offset == length) return 0;
    return if (a + offset == length) -1 else 1;
}

fn makeSuffixArray(text: []const i8, length: usize) SuffixOrder {
    var order = SuffixOrder{ .sa = @splat(0), .rank = @splat(0) };
    for (0..length) |i| order.sa[i] = i;
    for (1..length) |i| {
        const item = order.sa[i];
        var j = i;
        while (j > 0 and suffixCompare(text, length, item, order.sa[j - 1]) < 0) {
            order.sa[j] = order.sa[j - 1];
            j -= 1;
        }
        order.sa[j] = item;
    }
    for (0..length) |i| order.rank[order.sa[i]] = i;
    return order;
}

fn insertSuffix(nodes: []Node, node_count: *usize, text: []const i8,
                text_length: usize, start: usize) void {
    var current: usize = 0;
    var position = start;
    while (position < text_length) {
        const symbol = text[position];
        const child_id = nodes[current].child[slot(symbol)];
        if (child_id < 0) {
            const id = node_count.*;
            node_count.* += 1;
            const edge_length = text_length - position;
            nodes[id] = Node.empty();
            nodes[id].edge_start = position;
            nodes[id].edge_length = edge_length;
            nodes[id].depth = nodes[current].depth + edge_length;
            nodes[id].leaf_start = @intCast(start);
            nodes[current].child[slot(symbol)] = @intCast(id);
            return;
        }
        const child: usize = @intCast(child_id);
        var common: usize = 0;
        while (common < nodes[child].edge_length and position + common < text_length and
            text[position + common] == text[nodes[child].edge_start + common]) : (common += 1) {}
        if (common == nodes[child].edge_length) {
            position += common;
            current = child;
            continue;
        }

        const split = node_count.*;
        node_count.* += 1;
        const old_start = nodes[child].edge_start;
        nodes[split] = Node.empty();
        nodes[split].edge_start = old_start;
        nodes[split].edge_length = common;
        nodes[split].depth = nodes[current].depth + common;
        nodes[current].child[slot(symbol)] = @intCast(split);
        nodes[child].edge_start += common;
        nodes[child].edge_length -= common;
        nodes[split].child[slot(text[nodes[child].edge_start])] = @intCast(child);

        const new_start = position + common;
        const id = node_count.*;
        node_count.* += 1;
        const edge_length = text_length - new_start;
        nodes[id] = Node.empty();
        nodes[id].edge_start = new_start;
        nodes[id].edge_length = edge_length;
        nodes[id].depth = nodes[split].depth + edge_length;
        nodes[id].leaf_start = @intCast(start);
        nodes[split].child[slot(text[new_start])] = @intCast(id);
        return;
    }
}

fn summarize(nodes: []Node, id: usize, rank: []const usize, sigma: usize) void {
    if (nodes[id].leaf_start >= 0) {
        nodes[id].leaf_count = 1;
        nodes[id].sa_left = rank[@intCast(nodes[id].leaf_start)];
        nodes[id].sa_right = nodes[id].sa_left;
        return;
    }
    var children: [5]usize = @splat(0);
    var count: usize = 0;
    var symbol: i8 = -1;
    while (symbol < @as(i8, @intCast(sigma))) : (symbol += 1) {
        const child = nodes[id].child[slot(symbol)];
        if (child >= 0) {
            children[count] = @intCast(child);
            count += 1;
        }
    }
    var leaf_count: usize = 0;
    var left = max_suffixes;
    var right: usize = 0;
    for (children[0..count]) |child| {
        summarize(nodes, child, rank, sigma);
        leaf_count += nodes[child].leaf_count;
        left = @min(left, nodes[child].sa_left);
        right = @max(right, nodes[child].sa_right);
    }
    nodes[id].leaf_count = leaf_count;
    nodes[id].sa_left = left;
    nodes[id].sa_right = right;
}

fn setInterval(valid: *bool, interval: *[2]i32, nodes: []const Node,
               children: []const usize) void {
    if (children.len == 0) {
        valid.* = false;
        interval.* = @splat(-1);
        return;
    }
    valid.* = true;
    interval.* = .{
        @intCast(nodes[children[0]].sa_left),
        @intCast(nodes[children[children.len - 1]].sa_right),
    };
}

fn buildTray(nodes: []Node, node_count: usize, sigma: usize, text: []const i8) void {
    for (nodes[0..node_count]) |*node| node.sigma = node.leaf_count >= sigma;
    for (0..node_count) |id| {
        if (!nodes[id].sigma) continue;
        var children: [5]usize = @splat(0);
        var child_count: usize = 0;
        var symbol: i8 = -1;
        while (symbol < @as(i8, @intCast(sigma))) : (symbol += 1) {
            const child = nodes[id].child[slot(symbol)];
            if (child >= 0) {
                children[child_count] = @intCast(child);
                child_count += 1;
            }
        }
        var sigma_children: [5]usize = @splat(0);
        var sig_count: usize = 0;
        for (children[0..child_count]) |child| {
            if (nodes[child].sigma) {
                sigma_children[sig_count] = child;
                sig_count += 1;
            }
        }
        nodes[id].sigma_child_count = sig_count;
        for (0..sig_count) |i| nodes[id].sigma_child[i] = @intCast(sigma_children[i]);
        if (sig_count == 0) {
            nodes[id].kind = 3;
            continue;
        }
        if (sig_count == 1) {
            nodes[id].kind = 2;
            const child = sigma_children[0];
            nodes[id].only_sigma_child = @intCast(child);
            nodes[id].separator = text[nodes[child].edge_start];
            var left: [5]usize = @splat(0);
            var right: [5]usize = @splat(0);
            var left_count: usize = 0;
            var right_count: usize = 0;
            var after = false;
            for (children[0..child_count]) |item| {
                if (item == child) {
                    after = true;
                    continue;
                }
                if (!nodes[item].sigma) {
                    if (after) {
                        right[right_count] = item;
                        right_count += 1;
                    } else {
                        left[left_count] = item;
                        left_count += 1;
                    }
                }
            }
            setInterval(&nodes[id].left_valid, &nodes[id].left_interval, nodes,
                        left[0..left_count]);
            setInterval(&nodes[id].right_valid, &nodes[id].right_interval, nodes,
                        right[0..right_count]);
            continue;
        }

        nodes[id].kind = 1;
        var gaps: [6][5]usize = undefined;
        for (&gaps) |*row| row.* = @splat(0);
        var gap_counts: [6]usize = @splat(0);
        var gap: usize = 0;
        for (children[0..child_count]) |item| {
            if (nodes[item].sigma) {
                gap += 1;
            } else {
                gaps[gap][gap_counts[gap]] = item;
                gap_counts[gap] += 1;
            }
        }
        nodes[id].gap_count = sig_count + 1;
        for (0..sig_count + 1) |g| {
            if (gap_counts[g] > 0) {
                nodes[id].gap_left[g] = @intCast(nodes[gaps[g][0]].sa_left);
                nodes[id].gap_right[g] = @intCast(nodes[gaps[g][gap_counts[g] - 1]].sa_right);
            }
        }
        for (0..sigma) |wanted| {
            var exact: i32 = -1;
            var preceding: usize = 0;
            for (sigma_children[0..sig_count]) |child| {
                const first: usize = @intCast(text[nodes[child].edge_start]);
                if (first == wanted) {
                    exact = @intCast(child);
                    break;
                }
                if (first < wanted) preceding += 1;
            }
            if (exact >= 0) {
                nodes[id].child_by_symbol[wanted] = exact;
            } else if (gap_counts[preceding] > 0) {
                nodes[id].group_by_symbol[wanted] = @intCast(preceding);
            }
        }
    }
}

const PatternComparison = struct { order: i32, lcp: usize };

fn comparePattern(text: []const i8, text_length: usize, suffix: usize,
                  pattern: []const i8, q: usize, from: usize) PatternComparison {
    var i = from;
    while (i < q and suffix + i < text_length) : (i += 1) {
        if (text[suffix + i] != pattern[i]) {
            return .{ .order = if (text[suffix + i] < pattern[i]) -1 else 1, .lcp = i };
        }
    }
    return .{ .order = if (i == q) 1 else -1, .lcp = i };
}

fn intervalSearch(text: []const i8, text_length: usize, pattern: []const i8,
                  q: usize, sa: []const usize, lo: usize, hi: usize,
                  known: usize) i32 {
    var low: isize = @as(isize, @intCast(lo)) - 1;
    var high: isize = @as(isize, @intCast(hi)) + 1;
    var low_lcp = known;
    var high_lcp = known;
    while (high - low > 1) {
        const middle: usize = @intCast(@divTrunc(low + high, 2));
        const compared = comparePattern(text, text_length, sa[middle], pattern, q,
                                        @min(low_lcp, high_lcp));
        if (compared.order < 0) {
            low = @intCast(middle);
            low_lcp = compared.lcp;
        } else {
            high = @intCast(middle);
            high_lcp = compared.lcp;
        }
    }
    if (high > @as(isize, @intCast(hi))) return -1;
    const start = sa[@intCast(high)];
    if (start + q > text_length) return -1;
    for (0..q) |i| if (text[start + i] != pattern[i]) return -1;
    return @intCast(start);
}

fn trayQuery(text: []const i8, text_length: usize, pattern: []const i8,
             q: usize, sigma: usize, sa: []const usize,
             nodes: []const Node) i32 {
    var current: usize = 0;
    var matched: usize = 0;
    while (true) {
        const node = nodes[current];
        if (matched == q) return @intCast(sa[node.sa_left]);
        if (!node.sigma or node.kind == 3) {
            return intervalSearch(text, text_length, pattern, q, sa,
                                  node.sa_left, node.sa_right, matched);
        }
        const symbol: usize = @intCast(pattern[matched]);
        var next: i32 = -1;
        var interval_left: i32 = -1;
        var interval_right: i32 = -1;
        if (node.kind == 1) {
            next = node.child_by_symbol[symbol];
            if (next < 0) {
                const group = node.group_by_symbol[symbol];
                if (group < 0 or node.gap_left[@intCast(group)] < 0) return -1;
                interval_left = node.gap_left[@intCast(group)];
                interval_right = node.gap_right[@intCast(group)];
            }
        } else {
            next = node.only_sigma_child;
            if (pattern[matched] != node.separator) {
                if (pattern[matched] < node.separator) {
                    if (!node.left_valid) return -1;
                    interval_left = node.left_interval[0];
                    interval_right = node.left_interval[1];
                } else {
                    if (!node.right_valid) return -1;
                    interval_left = node.right_interval[0];
                    interval_right = node.right_interval[1];
                }
            }
        }
        if (interval_left >= 0) {
            return intervalSearch(text, text_length, pattern, q, sa,
                                  @intCast(interval_left), @intCast(interval_right), matched);
        }
        if (next < 0) return -1;
        const child = nodes[@intCast(next)];
        const representative = sa[child.sa_left];
        var edge_position = node.depth;
        while (matched < q and edge_position < child.depth) : ({ matched += 1; edge_position += 1; }) {
            if (text[representative + edge_position] != pattern[matched]) return -1;
        }
        if (matched == q) return @intCast(sa[child.sa_left]);
        if (edge_position != child.depth) return -1;
        current = @intCast(next);
    }
}

fn storeLe(output: [*]u8, offset: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |byte| output[offset + byte] = @truncate(bits >> @intCast(8 * byte));
}

export fn suffix_tray_pattern_query(input_opt: ?[*]const i64, length: usize,
    output_opt: ?[*]u8, capacity: usize) i64 {
    if (input_opt == null or length < 3 or length > max_input) return -1;
    const input = input_opt.?;
    const sigma64 = input[0];
    const n64 = input[1];
    const q64 = input[2];
    if (sigma64 < 2 or sigma64 > @as(i64, @intCast(max_sigma)) or
        n64 < 1 or n64 > @as(i64, @intCast(max_text)) or
        q64 < 1 or q64 > @as(i64, @intCast(max_pattern))) return -1;
    const sigma: usize = @intCast(sigma64);
    const n: usize = @intCast(n64);
    const q: usize = @intCast(q64);
    if (length != 3 + n + q) return -1;

    var text: [max_suffixes]i8 = @splat(-1);
    var pattern: [max_pattern]i8 = @splat(0);
    for (0..n) |i| {
        if (input[3 + i] < 0 or input[3 + i] >= sigma64) return -1;
        text[i] = @intCast(input[3 + i]);
    }
    for (0..q) |i| {
        if (input[3 + n + i] < 0 or input[3 + n + i] >= sigma64) return -1;
        pattern[i] = @intCast(input[3 + n + i]);
    }
    if (output_opt == null or capacity < max_output) return -2;

    const text_slice = text[0 .. n + 1];
    const pattern_slice = pattern[0..q];
    const order = makeSuffixArray(text_slice, n + 1);
    var nodes: [max_nodes]Node = undefined;
    for (&nodes) |*node| node.* = Node.empty();
    var node_count: usize = 1;
    for (0..n + 1) |start| insertSuffix(nodes[0..], &node_count, text_slice, n + 1, start);
    summarize(nodes[0..], 0, order.rank[0 .. n + 1], sigma);
    buildTray(nodes[0..], node_count, sigma, text_slice);
    const found = trayQuery(text_slice, n + 1, pattern_slice, q, sigma,
                            order.sa[0 .. n + 1], nodes[0..node_count]);

    const output = output_opt.?;
    storeLe(output, 0, if (found < 0) 0 else 1);
    storeLe(output, 8, @as(i64, found));
    return @intCast(max_output);
}
