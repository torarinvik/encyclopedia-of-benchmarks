const MAX_DEPTH: usize = 2;
const MAX_INPUT: usize = 25;
const MAX_PAIRS: usize = 64;

#[derive(Clone, Copy, Default)]
struct Point { x: i64, y: i64 }
#[derive(Clone, Copy, Default)]
struct Triangle { v: [usize; 3] }
#[derive(Clone, Copy, Default)]
struct Edge { a: usize, b: usize }

struct State {
    points: [Point; 5],
    triangles: [Triangle; 4],
    edges: [Edge; 8],
    pairs: [(i64, i64); MAX_PAIRS],
    vertex_count: usize,
    triangle_count: usize,
    edge_count: usize,
    pair_count: usize,
    failed: bool,
}

impl State {
    fn new() -> Self {
        Self {
            points: [Point::default(); 5], triangles: [Triangle::default(); 4],
            edges: [Edge::default(); 8], pairs: [(0, 0); MAX_PAIRS],
            vertex_count: 0, triangle_count: 0, edge_count: 0, pair_count: 0, failed: false,
        }
    }

    fn add_edge(&mut self, a0: usize, b0: usize) -> bool {
        let (a, b) = if a0 < b0 { (a0, b0) } else { (b0, a0) };
        if self.edges[..self.edge_count].iter().any(|e| e.a == a && e.b == b) { return true; }
        if self.edge_count >= self.edges.len() { return false; }
        self.edges[self.edge_count] = Edge { a, b };
        self.edge_count += 1;
        true
    }

    fn edge_hits_box(&self, edge: Edge, xmin: i64, ymin: i64, xmax: i64, ymax: i64) -> bool {
        let a = self.points[edge.a];
        let b = self.points[edge.b];
        if (xmin <= a.x && a.x <= xmax && ymin <= a.y && a.y <= ymax) ||
            (xmin <= b.x && b.x <= xmax && ymin <= b.y && b.y <= ymax) { return true; }
        segments_intersect(a, b, Point{x:xmin,y:ymin}, Point{x:xmax,y:ymin}) ||
            segments_intersect(a, b, Point{x:xmax,y:ymin}, Point{x:xmax,y:ymax}) ||
            segments_intersect(a, b, Point{x:xmax,y:ymax}, Point{x:xmin,y:ymax}) ||
            segments_intersect(a, b, Point{x:xmin,y:ymax}, Point{x:xmin,y:ymin})
    }

    fn stopping(&self, xmin: i64, ymin: i64, xmax: i64, ymax: i64) -> bool {
        let touched: Vec<Edge> = self.edges[..self.edge_count].iter().copied()
            .filter(|edge| self.edge_hits_box(*edge, xmin, ymin, xmax, ymax)).collect();
        if touched.is_empty() { return true; }
        (0..self.vertex_count).any(|v| touched.iter().all(|e| e.a == v || e.b == v))
    }

    fn triangle_hits_box(&self, tid: usize, xmin: i64, ymin: i64, xmax: i64, ymax: i64) -> bool {
        let t = self.triangles[tid].v;
        let p = [self.points[t[0]], self.points[t[1]], self.points[t[2]]];
        if p.iter().any(|v| xmin <= v.x && v.x <= xmax && ymin <= v.y && v.y <= ymax) { return true; }
        let corners = [Point{x:xmin,y:ymin}, Point{x:xmax,y:ymin},
                       Point{x:xmax,y:ymax}, Point{x:xmin,y:ymax}];
        if corners.iter().any(|q| point_in_triangle(*q, p[0], p[1], p[2])) { return true; }
        (0..3).any(|i| {
            let a = p[i]; let b = p[(i + 1) % 3];
            segments_intersect(a,b,corners[0],corners[1]) ||
            segments_intersect(a,b,corners[1],corners[2]) ||
            segments_intersect(a,b,corners[2],corners[3]) ||
            segments_intersect(a,b,corners[3],corners[0])
        })
    }

    fn append_pair(&mut self, key: i64, triangle_id: usize) {
        if self.pair_count >= MAX_PAIRS { self.failed = true; return; }
        self.pairs[self.pair_count] = (key, triangle_id as i64);
        self.pair_count += 1;
    }

    fn visit(&mut self, depth: usize, ix: usize, iy: usize, path: usize) {
        if self.failed { return; }
        let size = 8_i64 >> depth;
        let xmin = ix as i64 * size; let xmax = xmin + size;
        let ymax = 8 - iy as i64 * size; let ymin = ymax - size;
        if !self.stopping(xmin, ymin, xmax, ymax) {
            if depth >= MAX_DEPTH { self.failed = true; return; }
            for q in 0..4 {
                self.visit(depth + 1, 2 * ix + (q & 1), 2 * iy + (q >> 1), 4 * path + q);
            }
            return;
        }
        let key = (path << (2 * (MAX_DEPTH - depth))) as i64;
        for tid in 0..self.triangle_count {
            if self.triangle_hits_box(tid, xmin, ymin, xmax, ymax) { self.append_pair(key, tid); }
        }
    }
}

fn orient(a: Point, b: Point, c: Point) -> i64 {
    (b.x - a.x) * (c.y - a.y) - (b.y - a.y) * (c.x - a.x)
}

fn on_segment(a: Point, b: Point, p: Point) -> bool {
    a.x.min(b.x) <= p.x && p.x <= a.x.max(b.x) && a.y.min(b.y) <= p.y && p.y <= a.y.max(b.y)
}

fn segments_intersect(a: Point, b: Point, c: Point, d: Point) -> bool {
    let o1 = orient(a,b,c); let o2 = orient(a,b,d); let o3 = orient(c,d,a); let o4 = orient(c,d,b);
    if ((o1 < 0 && o2 > 0) || (o1 > 0 && o2 < 0)) &&
       ((o3 < 0 && o4 > 0) || (o3 > 0 && o4 < 0)) { return true; }
    (o1 == 0 && on_segment(a,b,c)) || (o2 == 0 && on_segment(a,b,d)) ||
        (o3 == 0 && on_segment(c,d,a)) || (o4 == 0 && on_segment(c,d,b))
}

fn point_in_triangle(p: Point, a: Point, b: Point, c: Point) -> bool {
    orient(a,b,p) >= 0 && orient(b,c,p) >= 0 && orient(c,a,p) >= 0
}

fn parse(state: &mut State, words: &[i64]) -> bool {
    if words.len() < 2 || words.len() > MAX_INPUT { return false; }
    if !((words[0] == 4 && words[1] == 2) || (words[0] == 5 && words[1] == 4)) { return false; }
    state.vertex_count = words[0] as usize; state.triangle_count = words[1] as usize;
    if words.len() != 2 + 2 * state.vertex_count + 3 * state.triangle_count { return false; }
    let corners = [(0,0),(8,0),(8,8),(0,8)];
    for i in 0..4 {
        if words[2 + 2*i] != corners[i].0 || words[3 + 2*i] != corners[i].1 { return false; }
        state.points[i] = Point{x:corners[i].0,y:corners[i].1};
    }
    if state.vertex_count == 5 {
        if words[10] != 4 || words[11] != 4 { return false; }
        state.points[4] = Point{x:4,y:4};
    }
    let start = 2 + 2 * state.vertex_count;
    for i in 0..state.triangle_count {
        let mut tri = [0_usize; 3];
        for j in 0..3 {
            let id = words[start + 3*i + j];
            if id < 0 || id >= state.vertex_count as i64 { return false; }
            tri[j] = id as usize;
        }
        state.triangles[i] = Triangle{v:tri};
    }
    if state.vertex_count == 4 {
        let d02 = state.triangles[0].v == [0,1,2] && state.triangles[1].v == [0,2,3];
        let d13 = state.triangles[0].v == [0,1,3] && state.triangles[1].v == [1,2,3];
        if !d02 && !d13 { return false; }
    } else if state.triangles.map(|t| t.v) != [[0,1,4],[1,2,4],[2,3,4],[3,0,4]] {
        return false;
    }
    for i in 0..state.triangle_count {
        let t = state.triangles[i].v;
        if !state.add_edge(t[0],t[1]) || !state.add_edge(t[1],t[2]) || !state.add_edge(t[2],t[0]) { return false; }
    }
    true
}

fn store_i64_le(output: &mut [u8], offset: usize, value: i64) {
    output[offset..offset + 8].copy_from_slice(&value.to_le_bytes());
}

#[no_mangle]
pub unsafe extern "C" fn star_quadtree_fat_triangulation(
    input: *const i64, length: usize, output: *mut u8, capacity: usize,
) -> i64 {
    if input.is_null() || length < 2 || length > MAX_INPUT { return -1; }
    let words = unsafe { std::slice::from_raw_parts(input, length) };
    let mut state = State::new();
    if !parse(&mut state, words) { return -1; }
    state.visit(0, 0, 0, 0);
    if state.failed { return -1; }
    let bytes = (1 + 2 * state.pair_count) * 8;
    if output.is_null() || capacity < bytes { return -2; }
    let out = unsafe { std::slice::from_raw_parts_mut(output, capacity) };
    store_i64_le(out, 0, state.pair_count as i64);
    for i in 0..state.pair_count {
        store_i64_le(out, 8 + 16*i, state.pairs[i].0);
        store_i64_le(out, 16 + 16*i, state.pairs[i].1);
    }
    bytes as i64
}
