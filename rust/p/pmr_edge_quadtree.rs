const MAX_SEGMENTS: usize = 8;
const MAX_DEPTH: usize = 8;
const MAX_NODES: usize = 2048;
const MAX_INPUT: usize = 35;

#[derive(Clone, Copy)]
struct Node {
    parent: i32,
    quadrant: i32,
    depth: i32,
    bounds: [i64; 4],
    children: [i32; 4],
    ids: [i32; MAX_SEGMENTS],
    id_count: usize,
}

impl Node {
    const EMPTY: Self = Self {
        parent: -1, quadrant: -1, depth: 0, bounds: [0; 4],
        children: [-1; 4], ids: [0; MAX_SEGMENTS], id_count: 0,
    };
}

struct State {
    nodes: [Node; MAX_NODES],
    used: usize,
    segments: [[i64; 4]; MAX_SEGMENTS],
}

fn orient(a: (i64, i64), b: (i64, i64), c: (i64, i64)) -> i64 {
    (b.0 - a.0) * (c.1 - a.1) - (b.1 - a.1) * (c.0 - a.0)
}
fn between(a: i64, b: i64, p: i64) -> bool { (a <= p && p <= b) || (b <= p && p <= a) }
fn on_segment(a: (i64, i64), b: (i64, i64), p: (i64, i64)) -> bool {
    between(a.0, b.0, p.0) && between(a.1, b.1, p.1)
}
fn segments_intersect(a: (i64, i64), b: (i64, i64), c: (i64, i64), d: (i64, i64)) -> bool {
    let (o1, o2, o3, o4) = (orient(a,b,c), orient(a,b,d), orient(c,d,a), orient(c,d,b));
    (((o1 < 0 && o2 > 0) || (o1 > 0 && o2 < 0)) &&
     ((o3 < 0 && o4 > 0) || (o3 > 0 && o4 < 0))) ||
    (o1 == 0 && on_segment(a,b,c)) || (o2 == 0 && on_segment(a,b,d)) ||
    (o3 == 0 && on_segment(c,d,a)) || (o4 == 0 && on_segment(c,d,b))
}
fn intersects_box(state: &State, sid: usize, bounds: [i64; 4]) -> bool {
    let s = state.segments[sid];
    let a = (2 * s[0], 2 * s[1]);
    let b = (2 * s[2], 2 * s[3]);
    let [lx, ly, hx, hy] = bounds;
    let inside = |p: (i64, i64)| lx <= p.0 && p.0 <= hx && ly <= p.1 && p.1 <= hy;
    if inside(a) || inside(b) { return true; }
    segments_intersect(a,b,(lx,ly),(hx,ly)) || segments_intersect(a,b,(hx,ly),(hx,hy)) ||
    segments_intersect(a,b,(hx,hy),(lx,hy)) || segments_intersect(a,b,(lx,hy),(lx,ly))
}
fn add_node(state: &mut State, id: usize, parent: i32, q: i32, depth: i32, bounds: [i64; 4]) {
    state.nodes[id] = Node { parent, quadrant: q, depth, bounds, ..Node::EMPTY };
}
fn insert(state: &mut State, node_id: usize, sid: usize, threshold: usize) -> bool {
    if state.nodes[node_id].children[0] >= 0 {
        for q in 0..4 {
            let child = state.nodes[node_id].children[q] as usize;
            if intersects_box(state, sid, state.nodes[child].bounds) && !insert(state, child, sid, threshold) {
                return false;
            }
        }
        return true;
    }
    let old_count = state.nodes[node_id].id_count;
    if old_count >= MAX_SEGMENTS { return false; }
    state.nodes[node_id].ids[old_count] = sid as i32;
    state.nodes[node_id].id_count += 1;
    if state.nodes[node_id].id_count <= threshold { return true; }
    let depth = state.nodes[node_id].depth as usize;
    if depth >= MAX_DEPTH || state.used + 4 > MAX_NODES { return false; }

    let previous = state.nodes[node_id].ids;
    let previous_count = state.nodes[node_id].id_count;
    let [xmin, ymin, xmax, ymax] = state.nodes[node_id].bounds;
    let mx = xmin + (xmax - xmin) / 2;
    let my = ymin + (ymax - ymin) / 2;
    let base = state.used;
    for q in 0..4 {
        let x0 = if q % 2 == 0 { xmin } else { mx };
        let x1 = if q % 2 == 0 { mx } else { xmax };
        let y0 = if q < 2 { my } else { ymin };
        let y1 = if q < 2 { ymax } else { my };
        add_node(state, base + q, node_id as i32, q as i32, depth as i32 + 1, [x0,y0,x1,y1]);
    }
    state.used += 4;
    state.nodes[node_id].children = [base as i32, (base+1) as i32, (base+2) as i32, (base+3) as i32];
    state.nodes[node_id].id_count = 0;
    for sid in previous[..previous_count].iter().copied() {
        for q in 0..4 {
            let child = base + q;
            if intersects_box(state, sid as usize, state.nodes[child].bounds) &&
                !insert(state, child, sid as usize, threshold) { return false; }
        }
    }
    true
}
fn preorder(state: &State, id: usize, order: &mut [usize; MAX_NODES], count: &mut usize) {
    order[*count] = id;
    *count += 1;
    if state.nodes[id].children[0] >= 0 {
        for child in state.nodes[id].children {
            preorder(state, child as usize, order, count);
        }
    }
}
fn store_le(output: &mut [u8], offset: usize, value: i64) {
    output[offset..offset + 8].copy_from_slice(&value.to_le_bytes());
}
fn solve(input: &[i64], output: &mut [u8]) -> i64 {
    if input.len() < 2 || input.len() > MAX_INPUT || input[0] < 0 || input[0] > 8 ||
        input[1] < 1 || input[1] > 8 { return -1; }
    let count = input[0] as usize;
    let threshold = input[1] as usize;
    if input.len() != 2 + 4 * count { return -1; }
    let mut state = State { nodes: [Node::EMPTY; MAX_NODES], used: 1, segments: [[0; 4]; MAX_SEGMENTS] };
    for sid in 0..count {
        for k in 0..4 {
            let value = input[2 + 4 * sid + k];
            if !(0..=255).contains(&value) { return -1; }
            state.segments[sid][k] = value;
        }
        if state.segments[sid][0] == state.segments[sid][2] && state.segments[sid][1] == state.segments[sid][3] { return -1; }
    }
    add_node(&mut state, 0, -1, -1, 0, [-1,-1,511,511]);
    for sid in 0..count { if !insert(&mut state, 0, sid, threshold) { return -1; } }
    let mut order = [0usize; MAX_NODES];
    let mut remap = [0i64; MAX_NODES];
    let mut node_count = 0;
    preorder(&state, 0, &mut order, &mut node_count);
    let bytes: usize = 16 + order[..node_count].iter().map(|&id| 32 + state.nodes[id].id_count * 8).sum::<usize>();
    if output.len() < bytes { return -2; }
    for i in 0..node_count { remap[order[i]] = i as i64; }
    store_le(output, 0, node_count as i64);
    store_le(output, 8, count as i64);
    let mut cursor = 16;
    for i in 0..node_count {
        let node = state.nodes[order[i]];
        store_le(output, cursor, if node.parent < 0 { -1 } else { remap[node.parent as usize] }); cursor += 8;
        store_le(output, cursor, node.quadrant as i64); cursor += 8;
        store_le(output, cursor, node.depth as i64); cursor += 8;
        store_le(output, cursor, node.id_count as i64); cursor += 8;
        for sid in node.ids[..node.id_count].iter().copied() { store_le(output, cursor, sid as i64); cursor += 8; }
    }
    bytes as i64
}

#[no_mangle]
pub unsafe extern "C" fn pmr_edge_quadtree(input: *const i64, length: usize,
        output: *mut u8, capacity: usize) -> i64 {
    if input.is_null() || length < 2 || length > MAX_INPUT { return -1; }
    let input = unsafe { std::slice::from_raw_parts(input, length) };
    if output.is_null() { return solve(input, &mut []); }
    let output = unsafe { std::slice::from_raw_parts_mut(output, capacity) };
    solve(input, output)
}
