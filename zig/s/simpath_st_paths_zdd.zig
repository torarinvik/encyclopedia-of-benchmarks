/// Frontier/mate construction of a reduced ZDD for undirected s-t paths.
const MAX_N: usize = 8;
const MAX_M: usize = 9;
const MAX_STATES: usize = 1023;
const MAX_ZDD: usize = 511;
const MAX_INPUT: usize = 23;
const RADIX: i64 = 2048;

const Edge = struct { u: usize, v: usize };
const Memo = struct { level: usize, mate: [MAX_N]u8, result: i32 };
const ZNode = struct { level: usize, low: i32, high: i32 };
const Context = struct {
    n: usize,
    m: usize,
    source: usize,
    target: usize,
    memo_count: usize = 0,
    node_count: usize = 0,
    edges: [MAX_M]Edge,
    last: [MAX_N]i32,
    memo: [MAX_STATES]Memo,
    nodes: [MAX_ZDD]ZNode,
};
const Transition = struct { status: u8, state: [MAX_N]u8 };

fn degreeOf(mate: [MAX_N]u8, vertex: usize) usize {
    if (mate[vertex] == vertex + 1) return 0;
    if (mate[vertex] == 0) return 2;
    return 1;
}

// Status 0 prunes, 1 returns a suffix state, and 2 is the one-terminal.
fn transition(c: *const Context, level: usize, mate: [MAX_N]u8, selected: bool) Transition {
    var next = mate;
    if (selected) {
        const u = c.edges[level].u;
        const v = c.edges[level].v;
        const du = degreeOf(next, u);
        const dv = degreeOf(next, v);
        if (du == 2 or dv == 2) return .{ .status = 0, .state = next };
        if ((u == c.source or u == c.target) and du == 1) return .{ .status = 0, .state = next };
        if ((v == c.source or v == c.target) and dv == 1) return .{ .status = 0, .state = next };
        const mu: usize = next[u];
        const mv: usize = next[v];
        if (mu == v + 1 and mv == u + 1) return .{ .status = 0, .state = next };
        if ((mu == c.source + 1 and mv == c.target + 1) or (mu == c.target + 1 and mv == c.source + 1)) {
            for (0..c.n) |w| {
                if (w != c.source and w != c.target and w != u and w != v and degreeOf(next, w) == 1)
                    return .{ .status = 0, .state = next };
            }
            return .{ .status = 2, .state = next };
        }
        next[u] = 0;
        next[v] = 0;
        next[mu - 1] = @intCast(mv);
        next[mv - 1] = @intCast(mu);
    }
    for (0..c.n) |w| {
        if (c.last[w] != @as(i32, @intCast(level))) continue;
        const degree = degreeOf(next, w);
        if (w == c.source or w == c.target) {
            if (degree == 0) return .{ .status = 0, .state = next };
        } else {
            if (degree == 1) return .{ .status = 0, .state = next };
            next[w] = @intCast(w + 1);
        }
    }
    return .{ .status = 1, .state = next };
}

fn memoFind(c: *const Context, level: usize, mate: [MAX_N]u8) ?i32 {
    for (0..c.memo_count) |i| {
        const entry = c.memo[i];
        if (entry.level != level) continue;
        var equal = true;
        for (0..c.n) |v| if (entry.mate[v] != mate[v]) { equal = false; break; };
        if (equal) return entry.result;
    }
    return null;
}

fn makeNode(c: *Context, level: usize, low: i32, high: i32) i32 {
    if (high == 0) return low;
    for (0..c.node_count) |i| {
        const node = c.nodes[i];
        if (node.level == level and node.low == low and node.high == high) return @intCast(i + 2);
    }
    if (c.node_count >= MAX_ZDD) return -1;
    c.nodes[c.node_count] = .{ .level = level, .low = low, .high = high };
    c.node_count += 1;
    return @intCast(c.node_count + 1);
}

fn solve(c: *Context, level: usize, mate: [MAX_N]u8) i32 {
    if (level == c.m) return 0;
    if (memoFind(c, level, mate)) |cached| return cached;
    const low_step = transition(c, level, mate, false);
    const low: i32 = if (low_step.status == 0) 0 else solve(c, level + 1, low_step.state);
    const high_step = transition(c, level, mate, true);
    const high: i32 = if (high_step.status == 0) 0 else if (high_step.status == 2) 1 else solve(c, level + 1, high_step.state);
    const result = makeNode(c, level, low, high);
    if (result < 0 or c.memo_count >= MAX_STATES) return -1;
    c.memo[c.memo_count] = .{ .level = level, .mate = mate, .result = result };
    c.memo_count += 1;
    return result;
}

fn reachableNodes(c: *const Context, root: i32) usize {
    var seen: [MAX_ZDD + 2]bool = @splat(false);
    var stack: [2 * MAX_ZDD + 3]i32 = @splat(0);
    var top: usize = 1;
    var count: usize = 0;
    stack[0] = root;
    while (top > 0) {
        top -= 1;
        const id = stack[top];
        if (id <= 1 or seen[@intCast(id)]) continue;
        seen[@intCast(id)] = true;
        count += 1;
        const node = c.nodes[@intCast(id - 2)];
        stack[top] = node.low;
        top += 1;
        stack[top] = node.high;
        top += 1;
    }
    return count;
}

pub export fn simpath_st_paths_zdd(input: [*c]const i64, length: usize) i64 {
    if (input == null or length < 4 or length > MAX_INPUT) return -1;
    const n64 = input[0];
    const m64 = input[1];
    const s64 = input[2];
    const t64 = input[3];
    if (n64 < 2 or n64 > MAX_N or m64 < 0 or m64 > MAX_M or s64 < 0 or s64 >= n64 or t64 < 0 or t64 >= n64 or s64 == t64)
        return -1;
    const n: usize = @intCast(n64);
    const m: usize = @intCast(m64);
    if (length != 4 + 2 * m) return -1;
    var c = Context{
        .n = n, .m = m, .source = @intCast(s64), .target = @intCast(t64),
        .memo_count = 0, .node_count = 0,
        .edges = @splat(.{ .u = 0, .v = 0 }), .last = @splat(-1),
        .memo = @splat(.{ .level = 0, .mate = @splat(0), .result = 0 }),
        .nodes = @splat(.{ .level = 0, .low = 0, .high = 0 }),
    };
    for (0..m) |i| {
        const u64 = input[4 + 2 * i];
        const v64 = input[5 + 2 * i];
        if (u64 < 0 or u64 >= v64 or v64 >= n64) return -1;
        for (0..i) |j| if (c.edges[j].u == u64 and c.edges[j].v == v64) return -1;
        const u: usize = @intCast(u64);
        const v: usize = @intCast(v64);
        c.edges[i] = .{ .u = u, .v = v };
        c.last[u] = @intCast(i);
        c.last[v] = @intCast(i);
    }
    var initial: [MAX_N]u8 = @splat(0);
    for (0..n) |v| initial[v] = @intCast(v + 1);
    const root = solve(&c, 0, initial);
    if (root < 0) return -1;
    var ways: [MAX_ZDD + 2]u16 = @splat(0);
    ways[1] = 1;
    for (2..c.node_count + 2) |id| {
        const node = c.nodes[id - 2];
        ways[id] = ways[@intCast(node.low)] + ways[@intCast(node.high)];
    }
    const path_count = ways[@intCast(root)];
    if (path_count >= @as(u16, @intCast(RADIX))) return -1;
    return @as(i64, @intCast(reachableNodes(&c, root))) * RADIX + @as(i64, path_count);
}
