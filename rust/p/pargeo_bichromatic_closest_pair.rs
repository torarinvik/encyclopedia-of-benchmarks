const MAX_POINTS: usize = 8;
const MAX_NODES: usize = 15;
const LEAF_SIZE: usize = 2;

#[derive(Clone, Copy, Default)]
struct Point { x: i64, y: i64 }
#[derive(Clone, Copy, Default)]
struct Node { left: i32, right: i32, start: usize, count: usize,
              min_x: i64, min_y: i64, max_x: i64, max_y: i64 }
#[derive(Clone, Copy)]
struct Tree { points: [Point; MAX_POINTS], order: [usize; MAX_POINTS],
              scratch: [usize; MAX_POINTS], nodes: [Node; MAX_NODES], used: usize }
impl Default for Tree {
    fn default() -> Self { Self { points: [Point::default(); MAX_POINTS], order: [0; MAX_POINTS],
        scratch: [0; MAX_POINTS], nodes: [Node::default(); MAX_NODES], used: 0 } }
}

fn build(t: &mut Tree, start: usize, count: usize) -> usize {
    let id = t.used; t.used += 1;
    let first = t.points[t.order[start]];
    let mut node = Node { left: -1, right: -1, start, count, min_x: first.x, min_y: first.y,
                          max_x: first.x, max_y: first.y };
    for i in 1..count {
        let p = t.points[t.order[start + i]];
        node.min_x = node.min_x.min(p.x); node.max_x = node.max_x.max(p.x);
        node.min_y = node.min_y.min(p.y); node.max_y = node.max_y.max(p.y);
    }
    if count <= LEAF_SIZE { t.nodes[id] = node; return id; }
    let axis_x = (node.max_x - node.min_x) > (node.max_y - node.min_y);
    let midpoint_twice = if axis_x { node.min_x + node.max_x } else { node.min_y + node.max_y };
    let mut left_count = 0;
    for i in 0..count {
        let p = t.points[t.order[start + i]];
        if 2 * (if axis_x { p.x } else { p.y }) < midpoint_twice { left_count += 1; }
    }
    if left_count == 0 || left_count == count {
        left_count = (count + 1) / 2;
        for i in 0..count { t.scratch[i] = t.order[start + i]; }
    } else {
        let (mut l, mut r) = (0, left_count);
        for i in 0..count {
            let index = t.order[start + i]; let p = t.points[index];
            let coordinate = if axis_x { p.x } else { p.y };
            if 2 * coordinate < midpoint_twice { t.scratch[l] = index; l += 1; }
            else { t.scratch[r] = index; r += 1; }
        }
    }
    for i in 0..count { t.order[start + i] = t.scratch[i]; }
    let left = build(t, start, left_count);
    let right = build(t, start + left_count, count - left_count);
    node.left = left as i32; node.right = right as i32; node.count = 0; t.nodes[id] = node; id
}

fn box_distance(a: Node, b: Node) -> i64 {
    let mut dx = 0; let mut dy = 0;
    if a.max_x < b.min_x { dx = b.min_x - a.max_x; } else if b.max_x < a.min_x { dx = a.min_x - b.max_x; }
    if a.max_y < b.min_y { dy = b.min_y - a.max_y; } else if b.max_y < a.min_y { dy = a.min_y - b.max_y; }
    dx * dx + dy * dy
}
fn search(a: &Tree, ai: usize, b: &Tree, bi: usize, best: &mut i64) {
    let na = a.nodes[ai]; let nb = b.nodes[bi];
    if box_distance(na, nb) > *best { return; }
    let al = na.left < 0; let bl = nb.left < 0;
    if al && bl {
        for i in 0..na.count { let p = a.points[a.order[na.start + i]];
            for j in 0..nb.count { let q = b.points[b.order[nb.start + j]];
                let dx = p.x - q.x; let dy = p.y - q.y; let d = dx * dx + dy * dy;
                if d < *best { *best = d; }
            }
        }
    } else if al {
        let l = nb.left as usize; let r = nb.right as usize;
        if box_distance(na, b.nodes[l]) < box_distance(na, b.nodes[r]) { search(a, ai, b, l, best); search(a, ai, b, r, best); }
        else { search(a, ai, b, r, best); search(a, ai, b, l, best); }
    } else if bl {
        let l = na.left as usize; let r = na.right as usize;
        if box_distance(nb, a.nodes[l]) < box_distance(nb, a.nodes[r]) { search(a, l, b, bi, best); search(a, r, b, bi, best); }
        else { search(a, r, b, bi, best); search(a, l, b, bi, best); }
    } else {
        let mut pairs = [(na.left as usize, nb.left as usize), (na.left as usize, nb.right as usize),
                         (na.right as usize, nb.left as usize), (na.right as usize, nb.right as usize)];
        let mut distances = [0_i64; 4];
        for i in 0..4 { distances[i] = box_distance(a.nodes[pairs[i].0], b.nodes[pairs[i].1]); }
        for i in 1..4 { let pair = pairs[i]; let d = distances[i]; let mut j = i;
            while j > 0 && d < distances[j - 1] { pairs[j] = pairs[j - 1]; distances[j] = distances[j - 1]; j -= 1; }
            pairs[j] = pair; distances[j] = d;
        }
        for (x, y) in pairs { search(a, x, b, y, best); }
    }
}

// Clean-room bounded ParGeo profile; full MIT attribution is in package LICENSE.txt.
#[no_mangle]
pub unsafe extern "C" fn pargeo_bichromatic_closest_pair(
    input: *const i64, length: usize, output: *mut u8, capacity: usize,
) -> i64 {
    if input.is_null() || length < 10 || length > 34 { return -1; }
    let values = std::slice::from_raw_parts(input, length);
    if !(2..=8).contains(&values[0]) || !(2..=8).contains(&values[1]) { return -1; }
    let na = values[0] as usize; let nb = values[1] as usize;
    if length != 2 + 2 * (na + nb) || values[2..].iter().any(|v| *v < -1_000_000 || *v > 1_000_000) { return -1; }
    if output.is_null() || capacity < 8 { return -2; }
    let mut a = Tree::default(); let mut b = Tree::default();
    for i in 0..na { a.points[i] = Point { x: values[2 + 2 * i], y: values[3 + 2 * i] }; a.order[i] = i; }
    let offset = 2 + 2 * na;
    for i in 0..nb { b.points[i] = Point { x: values[offset + 2 * i], y: values[offset + 2 * i + 1] }; b.order[i] = i; }
    let ra = build(&mut a, 0, na); let rb = build(&mut b, 0, nb);
    let mut best = i64::MAX; search(&a, ra, &b, rb, &mut best);
    std::ptr::copy_nonoverlapping(best.to_le_bytes().as_ptr(), output, 8);
    8
}
