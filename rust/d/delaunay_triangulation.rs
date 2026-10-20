const MAX_POINTS: usize = 8;
const MAX_VERTICES: usize = 11;
const MAX_WORK_TRIANGLES: usize = 17;
const MAX_WORK_EDGES: usize = 51;
const MAX_TRIANGLES: usize = 11;
const MAX_OUTPUT_BYTES: usize = 272;
const CIRCUMCIRCLE_EPSILON: f64 = 1e-4;

#[derive(Clone, Copy)]
struct Point { x: f64, y: f64 }
#[derive(Clone, Copy)]
struct Edge { a: usize, b: usize }
#[derive(Clone, Copy)]
struct Triangle { a: usize, b: usize, c: usize, cx: f64, cy: f64, radius_squared: f64 }

const EMPTY_POINT: Point = Point { x: 0.0, y: 0.0 };
const EMPTY_EDGE: Edge = Edge { a: 0, b: 0 };
const EMPTY_TRIANGLE: Triangle = Triangle { a: 0, b: 0, c: 0, cx: 0.0, cy: 0.0, radius_squared: 0.0 };

fn orient(ax: i64, ay: i64, bx: i64, by: i64, cx: i64, cy: i64) -> i64 {
    (bx - ax) * (cy - ay) - (by - ay) * (cx - ax)
}
fn incircle(ax: i64, ay: i64, bx: i64, by: i64, cx: i64, cy: i64, dx: i64, dy: i64) -> i64 {
    let (x1, y1) = (ax - dx, ay - dy);
    let (x2, y2) = (bx - dx, by - dy);
    let (x3, y3) = (cx - dx, cy - dy);
    let q1 = x1 * x1 + y1 * y1;
    let q2 = x2 * x2 + y2 * y2;
    let q3 = x3 * x3 + y3 * y3;
    q1 * (x2 * y3 - y2 * x3) - q2 * (x1 * y3 - y1 * x3) + q3 * (x1 * y2 - y1 * x2)
}
fn same_edge(a: Edge, b: Edge) -> bool { (a.a == b.a && a.b == b.b) || (a.a == b.b && a.b == b.a) }

fn make_triangle(points: &[Point; MAX_VERTICES], a: usize, b: usize, c: usize) -> Triangle {
    let (p0, p1, p2) = (points[a], points[b], points[c]);
    let (ax, ay, bx, by) = (p1.x - p0.x, p1.y - p0.y, p2.x - p0.x, p2.y - p0.y);
    let m = p1.x * p1.x - p0.x * p0.x + p1.y * p1.y - p0.y * p0.y;
    let u = p2.x * p2.x - p0.x * p0.x + p2.y * p2.y - p0.y * p0.y;
    let scale = 1.0 / (2.0 * (ax * by - ay * bx));
    let cx = ((p2.y - p0.y) * m + (p0.y - p1.y) * u) * scale;
    let cy = ((p0.x - p2.x) * m + (p1.x - p0.x) * u) * scale;
    let (dx, dy) = (p0.x - cx, p0.y - cy);
    Triangle { a, b, c, cx, cy, radius_squared: dx * dx + dy * dy }
}
fn sort_indices(a: &mut usize, b: &mut usize, c: &mut usize) {
    if *a > *b { std::mem::swap(a, b); }
    if *b > *c { std::mem::swap(b, c); }
    if *a > *b { std::mem::swap(a, b); }
}
fn triangle_less(a: Triangle, b: Triangle) -> bool {
    (a.a, a.b, a.c) < (b.a, b.b, b.c)
}
fn put_i64(output: &mut [u8; MAX_OUTPUT_BYTES], offset: usize, value: i64) {
    output[offset..offset + 8].copy_from_slice(&value.to_le_bytes());
}

#[no_mangle]
pub unsafe extern "C" fn delaunay_triangulation(values: *const i64, length: usize,
        output: *mut u8, capacity: usize) -> i64 {
    if values.is_null() || length < 7 || length > 17 { return -1; }
    if *values < 3 || *values > MAX_POINTS as i64 { return -1; }
    let n = *values as usize;
    if length != 1 + 2 * n { return -1; }
    let mut ix = [0i64; MAX_POINTS];
    let mut iy = [0i64; MAX_POINTS];
    let mut points = [EMPTY_POINT; MAX_VERTICES];
    let (mut min_x, mut max_x, mut min_y, mut max_y) = (0i64, 0i64, 0i64, 0i64);
    for i in 0..n {
        let x = *values.add(1 + 2 * i);
        let y = *values.add(2 + 2 * i);
        if !(-10..=10).contains(&x) || !(-10..=10).contains(&y) { return -1; }
        for j in 0..i { if ix[j] == x && iy[j] == y { return -1; } }
        ix[i] = x; iy[i] = y; points[i] = Point { x: x as f64, y: y as f64 };
        if i == 0 { min_x = x; max_x = x; min_y = y; max_y = y; }
        else { min_x = min_x.min(x); max_x = max_x.max(x); min_y = min_y.min(y); max_y = max_y.max(y); }
    }
    for a in 0..n { for b in a + 1..n { for c in b + 1..n {
        if orient(ix[a], iy[a], ix[b], iy[b], ix[c], iy[c]) == 0 { return -1; }
    } } }
    for a in 0..n { for b in a + 1..n { for c in b + 1..n { for d in c + 1..n {
        if incircle(ix[a], iy[a], ix[b], iy[b], ix[c], iy[c], ix[d], iy[d]) == 0 { return -1; }
    } } } }

    let dmax = (max_x - min_x).max(max_y - min_y);
    let midx = (min_x as f64 + max_x as f64) / 2.0;
    let midy = (min_y as f64 + max_y as f64) / 2.0;
    let (s0, s1, s2) = (n, n + 1, n + 2);
    points[s0] = Point { x: midx - 20.0 * dmax as f64, y: midy - dmax as f64 };
    points[s1] = Point { x: midx, y: midy + 20.0 * dmax as f64 };
    points[s2] = Point { x: midx + 20.0 * dmax as f64, y: midy - dmax as f64 };
    for a in 0..n + 3 { for b in a + 1..n + 3 { for c in b + 1..n + 3 {
        let area2 = (points[b].x - points[a].x) * (points[c].y - points[a].y)
                  - (points[b].y - points[a].y) * (points[c].x - points[a].x);
        if area2 == 0.0 { return -1; }
    } } }

    let mut current = [EMPTY_TRIANGLE; MAX_WORK_TRIANGLES];
    let mut next = [EMPTY_TRIANGLE; MAX_WORK_TRIANGLES];
    let mut edges = [EMPTY_EDGE; MAX_WORK_EDGES];
    let mut current_count = 1usize;
    current[0] = make_triangle(&points, s0, s1, s2);
    for p in 0..n {
        let mut edge_count = 0usize;
        let mut next_count = 0usize;
        for i in 0..current_count {
            let t = current[i];
            let dx = t.cx - points[p].x;
            let dy = t.cy - points[p].y;
            if dx * dx + dy * dy - t.radius_squared <= CIRCUMCIRCLE_EPSILON {
                edges[edge_count] = Edge { a: t.a, b: t.b };
                edges[edge_count + 1] = Edge { a: t.b, b: t.c };
                edges[edge_count + 2] = Edge { a: t.a, b: t.c };
                edge_count += 3;
            } else {
                if next_count >= MAX_WORK_TRIANGLES { return -1; }
                next[next_count] = t;
                next_count += 1;
            }
        }
        let mut remove = [false; MAX_WORK_EDGES];
        for i in 0..edge_count { for j in 0..edge_count {
            if i != j && same_edge(edges[i], edges[j]) { remove[i] = true; remove[j] = true; }
        } }
        for i in 0..edge_count {
            if !remove[i] {
                if next_count >= MAX_WORK_TRIANGLES { return -1; }
                next[next_count] = make_triangle(&points, edges[i].a, edges[i].b, p);
                next_count += 1;
            }
        }
        for i in 0..next_count { current[i] = next[i]; }
        current_count = next_count;
    }
    let mut result = [EMPTY_TRIANGLE; MAX_TRIANGLES];
    let mut result_count = 0usize;
    for i in 0..current_count {
        let mut t = current[i];
        if t.a >= n || t.b >= n || t.c >= n { continue; }
        if result_count >= MAX_TRIANGLES { return -1; }
        sort_indices(&mut t.a, &mut t.b, &mut t.c);
        let mut j = result_count;
        result_count += 1;
        while j > 0 && triangle_less(t, result[j - 1]) { result[j] = result[j - 1]; j -= 1; }
        result[j] = t;
    }
    if result_count == 0 { return -1; }
    let mut staged = [0u8; MAX_OUTPUT_BYTES];
    put_i64(&mut staged, 0, result_count as i64);
    for i in 0..result_count {
        put_i64(&mut staged, 8 + 24 * i, result[i].a as i64);
        put_i64(&mut staged, 16 + 24 * i, result[i].b as i64);
        put_i64(&mut staged, 24 + 24 * i, result[i].c as i64);
    }
    let required = 8 + 24 * result_count;
    if output.is_null() || capacity < required { return -2; }
    std::ptr::copy_nonoverlapping(staged.as_ptr(), output, required);
    required as i64
}
