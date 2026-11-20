/// Frontier/mate construction of a reduced ZDD for undirected s-t paths.
const MAX_N: usize = 8;
const MAX_M: usize = 9;
const MAX_STATES: usize = 1023;
const MAX_ZDD: usize = 511;
const MAX_INPUT: usize = 23;
const RADIX: i64 = 2048;

#[derive(Clone, Copy, Default)]
struct Edge { u: usize, v: usize }
#[derive(Clone, Copy, Default)]
struct Memo { level: usize, mate: [u8; MAX_N], result: i32 }
#[derive(Clone, Copy, Default)]
struct ZNode { level: usize, low: i32, high: i32 }
struct Context {
    n: usize, m: usize, source: usize, target: usize,
    memo_count: usize, node_count: usize,
    edges: [Edge; MAX_M], last: [i32; MAX_N],
    memo: [Memo; MAX_STATES], nodes: [ZNode; MAX_ZDD],
}

fn degree_of(mate: &[u8; MAX_N], vertex: usize) -> usize {
    if mate[vertex] as usize == vertex + 1 { 0 }
    else if mate[vertex] == 0 { 2 }
    else { 1 }
}

// None means pruned; terminal status 1 denotes the one-terminal.
fn transition(c: &Context, level: usize, mate: &[u8; MAX_N], selected: bool)
    -> Option<([u8; MAX_N], bool)> {
    let mut next = *mate;
    if selected {
        let (u, v) = (c.edges[level].u, c.edges[level].v);
        let (du, dv) = (degree_of(&next, u), degree_of(&next, v));
        if du == 2 || dv == 2 { return None; }
        if (u == c.source || u == c.target) && du == 1 { return None; }
        if (v == c.source || v == c.target) && dv == 1 { return None; }
        let (mu, mv) = (next[u] as usize, next[v] as usize);
        if mu == v + 1 && mv == u + 1 { return None; }
        if (mu == c.source + 1 && mv == c.target + 1)
            || (mu == c.target + 1 && mv == c.source + 1) {
            for w in 0..c.n {
                if w != c.source && w != c.target && w != u && w != v
                    && degree_of(&next, w) == 1 { return None; }
            }
            return Some((next, true));
        }
        next[u] = 0;
        next[v] = 0;
        next[mu - 1] = mv as u8;
        next[mv - 1] = mu as u8;
    }
    for w in 0..c.n {
        if c.last[w] != level as i32 { continue; }
        let degree = degree_of(&next, w);
        if w == c.source || w == c.target {
            if degree == 0 { return None; }
        } else {
            if degree == 1 { return None; }
            next[w] = (w + 1) as u8;
        }
    }
    Some((next, false))
}

fn memo_find(c: &Context, level: usize, mate: &[u8; MAX_N]) -> Option<i32> {
    (0..c.memo_count).find_map(|i| {
        let entry = c.memo[i];
        if entry.level == level && entry.mate[..c.n] == mate[..c.n] { Some(entry.result) } else { None }
    })
}

fn make_node(c: &mut Context, level: usize, low: i32, high: i32) -> i32 {
    if high == 0 { return low; }
    for i in 0..c.node_count {
        let node = c.nodes[i];
        if node.level == level && node.low == low && node.high == high { return i as i32 + 2; }
    }
    if c.node_count >= MAX_ZDD { return -1; }
    c.nodes[c.node_count] = ZNode { level, low, high };
    c.node_count += 1;
    c.node_count as i32 + 1
}

fn solve(c: &mut Context, level: usize, mate: &[u8; MAX_N]) -> i32 {
    if level == c.m { return 0; }
    if let Some(cached) = memo_find(c, level, mate) { return cached; }
    let low = match transition(c, level, mate, false) {
        Some((next, _)) => solve(c, level + 1, &next), None => 0,
    };
    let high = match transition(c, level, mate, true) {
        None => 0,
        Some((_, true)) => 1,
        Some((next, false)) => solve(c, level + 1, &next),
    };
    let result = make_node(c, level, low, high);
    if result < 0 || c.memo_count >= MAX_STATES { return -1; }
    c.memo[c.memo_count] = Memo { level, mate: *mate, result };
    c.memo_count += 1;
    result
}

fn reachable_nodes(c: &Context, root: i32) -> usize {
    let mut seen = [false; MAX_ZDD + 2];
    let mut stack = [0i32; 2 * MAX_ZDD + 3];
    let mut top = 0usize;
    let mut count = 0usize;
    stack[top] = root; top += 1;
    while top > 0 {
        top -= 1;
        let id = stack[top];
        if id <= 1 || seen[id as usize] { continue; }
        seen[id as usize] = true;
        count += 1;
        let node = c.nodes[id as usize - 2];
        stack[top] = node.low; top += 1;
        stack[top] = node.high; top += 1;
    }
    count
}

#[no_mangle]
pub extern "C" fn simpath_st_paths_zdd(input: *const i64, length: usize) -> i64 {
    if input.is_null() || length < 4 || length > MAX_INPUT { return -1; }
    let values = unsafe { std::slice::from_raw_parts(input, length) };
    let (n64, m64, s64, t64) = (values[0], values[1], values[2], values[3]);
    if n64 < 2 || n64 > MAX_N as i64 || m64 < 0 || m64 > MAX_M as i64
        || s64 < 0 || s64 >= n64 || t64 < 0 || t64 >= n64 || s64 == t64
        || length != 4 + 2 * m64 as usize { return -1; }
    let (n, m, source, target) = (n64 as usize, m64 as usize, s64 as usize, t64 as usize);
    let mut c = Context {
        n, m, source, target, memo_count: 0, node_count: 0,
        edges: [Edge::default(); MAX_M], last: [-1; MAX_N],
        memo: [Memo::default(); MAX_STATES], nodes: [ZNode::default(); MAX_ZDD],
    };
    for i in 0..m {
        let (u64, v64) = (values[4 + 2 * i], values[5 + 2 * i]);
        if u64 < 0 || u64 >= v64 || v64 >= n64 { return -1; }
        for j in 0..i { if c.edges[j].u == u64 as usize && c.edges[j].v == v64 as usize { return -1; } }
        let (u, v) = (u64 as usize, v64 as usize);
        c.edges[i] = Edge { u, v }; c.last[u] = i as i32; c.last[v] = i as i32;
    }
    let mut initial = [0u8; MAX_N];
    for v in 0..n { initial[v] = (v + 1) as u8; }
    let root = solve(&mut c, 0, &initial);
    if root < 0 { return -1; }
    let mut ways = [0u16; MAX_ZDD + 2]; ways[1] = 1;
    for id in 2..c.node_count + 2 {
        let node = c.nodes[id - 2];
        ways[id] = ways[node.low as usize] + ways[node.high as usize];
    }
    let path_count = ways[root as usize] as usize;
    if path_count >= RADIX as usize { return -1; }
    reachable_nodes(&c, root) as i64 * RADIX + path_count as i64
}
