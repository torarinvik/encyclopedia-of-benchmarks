const MAX_VERTICES: usize = 32;
const MAX_QUERIES: usize = 32;
const MAX_INPUT: usize = 131;
const MAX_COORD: i64 = 1_000_000;

#[derive(Clone, Copy, Default)]
struct Point { x: i64, y: i64 }
fn sub(a: Point, b: Point) -> Point { Point { x: a.x - b.x, y: a.y - b.y } }
fn cross(a: Point, b: Point) -> i64 { a.x * b.y - a.y * b.x }
fn on_segment(a: Point, b: Point, p: Point) -> bool {
    let e = sub(b, a); let r = sub(p, a);
    cross(e, r) == 0 && p.x >= a.x.min(b.x) && p.x <= a.x.max(b.x)
        && p.y >= a.y.min(b.y) && p.y <= a.y.max(b.y)
}
fn valid_polygon(p: &[Point; MAX_VERTICES], n: usize) -> bool {
    for i in 0..n {
        let next = (i + 1) % n;
        if p[i].x == p[next].x && p[i].y == p[next].y { return false; }
        let edge = sub(p[next], p[i]);
        for j in 0..n {
            if j != i && j != next && cross(edge, sub(p[j], p[i])) <= 0 { return false; }
        }
        for j in i + 1..n {
            if p[i].x == p[j].x && p[i].y == p[j].y { return false; }
        }
    }
    true
}
fn contains_fan(fan: &[Point; MAX_VERTICES], m: usize, query: Point) -> i64 {
    let origin = Point::default();
    let first = cross(fan[0], query); let last = cross(fan[m - 1], query);
    if first < 0 || last > 0 { return 0; }
    if first == 0 { return if on_segment(origin, fan[0], query) { 1 } else { 0 }; }
    if last == 0 { return if on_segment(origin, fan[m - 1], query) { 1 } else { 0 }; }
    let (mut lo, mut hi) = (0usize, m);
    while hi - lo > 1 {
        let mid = (lo + hi) / 2;
        if cross(fan[mid], query) >= 0 { lo = mid; } else { hi = mid; }
    }
    let side = cross(sub(fan[lo + 1], fan[lo]), sub(query, fan[lo]));
    if side < 0 { return 0; }
    if side == 0 { return if on_segment(fan[lo], fan[lo + 1], query) { 1 } else { 0 }; }
    1
}
unsafe fn put_i64(out: *mut u8, offset: &mut usize, value: i64) {
    for (b, byte) in value.to_le_bytes().iter().enumerate() { *out.add(*offset + b) = *byte; }
    *offset += 8;
}

#[no_mangle]
pub unsafe extern "C" fn point_in_convex_polygon_log_query(v: *const i64, n: usize, out: *mut u8, cap: usize) -> i64 {
    if v.is_null() || n < 2 || n > MAX_INPUT { return -1; }
    let input = std::slice::from_raw_parts(v, n);
    if !(3..=32).contains(&input[0]) || !(0..=32).contains(&input[1]) { return -1; }
    let (vertices, queries) = (input[0] as usize, input[1] as usize);
    if n != 2 + 2 * vertices + 2 * queries { return -1; }
    let mut polygon = [Point::default(); MAX_VERTICES];
    let mut fan = [Point::default(); MAX_VERTICES];
    let mut query_points = [Point::default(); MAX_QUERIES];
    let mut answers = [0i64; MAX_QUERIES];
    let mut at = 2;
    for p in polygon.iter_mut().take(vertices) {
        *p = Point { x: input[at], y: input[at + 1] }; at += 2;
        if p.x < -MAX_COORD || p.x > MAX_COORD || p.y < -MAX_COORD || p.y > MAX_COORD { return -1; }
    }
    if !valid_polygon(&polygon, vertices) { return -1; }
    for p in query_points.iter_mut().take(queries) {
        *p = Point { x: input[at], y: input[at + 1] }; at += 2;
        if p.x < -MAX_COORD || p.x > MAX_COORD || p.y < -MAX_COORD || p.y > MAX_COORD { return -1; }
    }
    let mut pivot = 0;
    for i in 1..vertices {
        if polygon[i].x < polygon[pivot].x || (polygon[i].x == polygon[pivot].x && polygon[i].y < polygon[pivot].y) { pivot = i; }
    }
    for i in 0..vertices - 1 { fan[i] = sub(polygon[(pivot + i + 1) % vertices], polygon[pivot]); }
    for i in 0..queries { answers[i] = contains_fan(&fan, vertices - 1, sub(query_points[i], polygon[pivot])); }
    let needed = 8 * queries;
    if needed > cap || (needed != 0 && out.is_null()) { return -2; }
    let mut offset = 0;
    for answer in answers.iter().take(queries) { put_i64(out, &mut offset, *answer); }
    needed as i64
}
