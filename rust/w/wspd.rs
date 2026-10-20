const MAX_POINTS: usize = 8;
const MAX_NODES: usize = 15;
const MAX_PAIRS: usize = 28;
const MAX_OUTPUT_BYTES: usize = 456;

#[derive(Clone, Copy)]
struct Node {
    left: i32,
    right: i32,
    count: usize,
    mask: u64,
    cx: f64,
    cy: f64,
    radius: f64,
}
const EMPTY_NODE: Node = Node { left: -1, right: -1, count: 0, mask: 0, cx: 0.0, cy: 0.0, radius: 0.0 };
struct Context {
    x: [i64; MAX_POINTS],
    y: [i64; MAX_POINTS],
    nodes: [Node; MAX_NODES],
    left_masks: [u64; MAX_PAIRS],
    right_masks: [u64; MAX_PAIRS],
    next_node: usize,
    pair_count: usize,
    point_count: usize,
    separation: i64,
    overflow: bool,
}

fn point_less(ctx: &Context, a: usize, b: usize, axis: usize) -> bool {
    let (a0, b0, a1, b1) = if axis == 0 { (ctx.x[a], ctx.x[b], ctx.y[a], ctx.y[b]) }
        else { (ctx.y[a], ctx.y[b], ctx.x[a], ctx.x[b]) };
    a0 < b0 || (a0 == b0 && (a1 < b1 || (a1 == b1 && a < b)))
}

fn build_node(ctx: &mut Context, mask: u64) -> usize {
    let id = ctx.next_node;
    ctx.next_node += 1;
    ctx.nodes[id].left = -1;
    ctx.nodes[id].right = -1;
    ctx.nodes[id].mask = mask;
    let mut members = [0usize; MAX_POINTS];
    let mut used = 0usize;
    let (mut min_x, mut max_x, mut min_y, mut max_y) = (0i64, 0i64, 0i64, 0i64);
    for i in 0..ctx.point_count {
        if mask & (1u64 << i) != 0 {
            if used == 0 { min_x = ctx.x[i]; max_x = ctx.x[i]; min_y = ctx.y[i]; max_y = ctx.y[i]; }
            else {
                min_x = min_x.min(ctx.x[i]); max_x = max_x.max(ctx.x[i]);
                min_y = min_y.min(ctx.y[i]); max_y = max_y.max(ctx.y[i]);
            }
            members[used] = i;
            used += 1;
        }
    }
    ctx.nodes[id].count = used;
    ctx.nodes[id].cx = (min_x as f64 + max_x as f64) / 2.0;
    ctx.nodes[id].cy = (min_y as f64 + max_y as f64) / 2.0;
    let hx = (max_x as f64 - min_x as f64) / 2.0;
    let hy = (max_y as f64 - min_y as f64) / 2.0;
    ctx.nodes[id].radius = (hx * hx + hy * hy).sqrt();
    if used == 1 { return id; }

    let axis = if max_x - min_x >= max_y - min_y { 0 } else { 1 };
    for i in 1..used {
        let value = members[i];
        let mut j = i;
        while j > 0 && point_less(ctx, value, members[j - 1], axis) {
            members[j] = members[j - 1]; j -= 1;
        }
        members[j] = value;
    }
    let middle = used / 2;
    let mut left_mask = 0u64;
    let mut right_mask = 0u64;
    for i in 0..used {
        if i < middle { left_mask |= 1u64 << members[i]; }
        else { right_mask |= 1u64 << members[i]; }
    }
    let left = build_node(ctx, left_mask);
    let right = build_node(ctx, right_mask);
    ctx.nodes[id].left = left as i32;
    ctx.nodes[id].right = right as i32;
    id
}

fn well_separated(ctx: &Context, a: usize, b: usize) -> bool {
    let first = ctx.nodes[a];
    let second = ctx.nodes[b];
    let radius = first.radius.max(second.radius);
    let dx = first.cx - second.cx;
    let dy = first.cy - second.cy;
    (dx * dx + dy * dy).sqrt() - 2.0 * radius > ctx.separation as f64 * radius
}

fn cross_nodes(ctx: &mut Context, a: usize, b: usize) {
    if ctx.overflow { return; }
    if well_separated(ctx, a, b) {
        if ctx.pair_count >= MAX_PAIRS { ctx.overflow = true; return; }
        ctx.left_masks[ctx.pair_count] = ctx.nodes[a].mask;
        ctx.right_masks[ctx.pair_count] = ctx.nodes[b].mask;
        ctx.pair_count += 1;
        return;
    }
    if ctx.nodes[a].radius > ctx.nodes[b].radius {
        let left = ctx.nodes[a].left as usize;
        let right = ctx.nodes[a].right as usize;
        cross_nodes(ctx, left, b);
        cross_nodes(ctx, right, b);
    } else {
        let left = ctx.nodes[b].left as usize;
        let right = ctx.nodes[b].right as usize;
        cross_nodes(ctx, a, left);
        cross_nodes(ctx, a, right);
    }
}

fn visit_node(ctx: &mut Context, id: usize) {
    let left = ctx.nodes[id].left;
    if left < 0 { return; }
    let left = left as usize;
    let right = ctx.nodes[id].right as usize;
    visit_node(ctx, left);
    visit_node(ctx, right);
    cross_nodes(ctx, left, right);
}

fn put_i64(output: &mut [u8; MAX_OUTPUT_BYTES], offset: usize, value: i64) {
    output[offset..offset + 8].copy_from_slice(&value.to_le_bytes());
}

#[no_mangle]
pub unsafe extern "C" fn wspd(values: *const i64, length: usize, output: *mut u8, capacity: usize) -> i64 {
    if values.is_null() || length < 4 || length > 18 { return -1; }
    if *values < 1 || *values > MAX_POINTS as i64 || *values.add(1) < 1 || *values.add(1) > 8 { return -1; }
    let count = *values as usize;
    let separation = *values.add(1);
    if length != 2 + 2 * count { return -1; }
    let mut ctx = Context {
        x: [0; MAX_POINTS], y: [0; MAX_POINTS], nodes: [EMPTY_NODE; MAX_NODES],
        left_masks: [0; MAX_PAIRS], right_masks: [0; MAX_PAIRS],
        next_node: 0, pair_count: 0, point_count: count, separation, overflow: false,
    };
    for i in 0..count {
        let x = *values.add(2 + 2 * i);
        let y = *values.add(3 + 2 * i);
        if !(-1000..=1000).contains(&x) || !(-1000..=1000).contains(&y) { return -1; }
        for j in 0..i { if ctx.x[j] == x && ctx.y[j] == y { return -1; } }
        ctx.x[i] = x; ctx.y[i] = y;
    }
    let root = build_node(&mut ctx, (1u64 << count) - 1);
    visit_node(&mut ctx, root);
    if ctx.overflow { return -2; }
    let required = 8 + 16 * ctx.pair_count;
    let mut staged = [0u8; MAX_OUTPUT_BYTES];
    put_i64(&mut staged, 0, ctx.pair_count as i64);
    for i in 0..ctx.pair_count {
        put_i64(&mut staged, 8 + 16 * i, ctx.left_masks[i] as i64);
        put_i64(&mut staged, 16 + 16 * i, ctx.right_masks[i] as i64);
    }
    if output.is_null() || capacity < required { return -2; }
    std::ptr::copy_nonoverlapping(staged.as_ptr(), output, required);
    required as i64
}
