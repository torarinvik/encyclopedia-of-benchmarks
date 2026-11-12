const MAX_VERTICES: usize = 32;
const MAX_INPUT: usize = 131;
const MAX_COORD: i64 = 1_000_000;

#[derive(Clone, Copy, Default)]
struct Point { x: i64, y: i64 }

fn cross(a: Point, b: Point) -> i64 { a.x * b.y - a.y * b.x }
fn edge(p: &[Point; MAX_VERTICES], n: usize, i: usize) -> Point {
    let next = p[(i + 1) % n];
    Point { x: next.x - p[i].x, y: next.y - p[i].y }
}
fn half(v: Point) -> u8 { if v.y > 0 || (v.y == 0 && v.x >= 0) { 0 } else { 1 } }
fn angle_compare(a: Point, b: Point) -> i32 {
    let (ha, hb) = (half(a), half(b));
    if ha != hb { return if ha < hb { -1 } else { 1 }; }
    let turn = cross(a, b);
    if turn > 0 { -1 } else if turn < 0 { 1 } else { 0 }
}
fn valid_polygon(p: &[Point; MAX_VERTICES], n: usize) -> bool {
    let mut wraps = 0;
    for i in 0..n {
        let a = edge(p, n, i);
        let b = edge(p, n, (i + 1) % n);
        if (a.x == 0 && a.y == 0) || cross(a, b) <= 0 { return false; }
        if angle_compare(b, a) < 0 { wraps += 1; }
    }
    wraps == 1
}
fn rotate_lowest(p: &mut [Point; MAX_VERTICES], n: usize) {
    let mut first = 0;
    for i in 1..n {
        if p[i].y < p[first].y || (p[i].y == p[first].y && p[i].x < p[first].x) { first = i; }
    }
    let old = *p;
    for i in 0..n { p[i] = old[(first + i) % n]; }
}
unsafe fn put_i64(out: *mut u8, offset: &mut usize, value: i64) {
    for (b, byte) in value.to_le_bytes().iter().enumerate() { *out.add(*offset + b) = *byte; }
    *offset += 8;
}

#[no_mangle]
pub unsafe extern "C" fn minkowski_sum_convex_polygons(v: *const i64, n: usize,
        out: *mut u8, cap: usize) -> i64 {
    if v.is_null() || n < 14 || n > MAX_INPUT { return -1; }
    let input = std::slice::from_raw_parts(v, n);
    if !(3..=32).contains(&input[0]) || !(3..=32).contains(&input[1]) { return -1; }
    let (pn, qn) = (input[0] as usize, input[1] as usize);
    if n != 2 + 2 * pn + 2 * qn { return -1; }
    let mut p = [Point::default(); MAX_VERTICES];
    let mut q = [Point::default(); MAX_VERTICES];
    let mut sums = [Point::default(); 2 * MAX_VERTICES];
    let mut at = 2;
    for item in p.iter_mut().take(pn) {
        *item = Point { x: input[at], y: input[at + 1] }; at += 2;
        if item.x < -MAX_COORD || item.x > MAX_COORD || item.y < -MAX_COORD || item.y > MAX_COORD { return -1; }
    }
    for item in q.iter_mut().take(qn) {
        *item = Point { x: input[at], y: input[at + 1] }; at += 2;
        if item.x < -MAX_COORD || item.x > MAX_COORD || item.y < -MAX_COORD || item.y > MAX_COORD { return -1; }
    }
    if !valid_polygon(&p, pn) || !valid_polygon(&q, qn) { return -1; }
    rotate_lowest(&mut p, pn); rotate_lowest(&mut q, qn);
    let (mut i, mut j, mut count) = (0, 0, 0);
    while i < pn || j < qn {
        sums[count] = Point { x: p[i % pn].x + q[j % qn].x, y: p[i % pn].y + q[j % qn].y };
        count += 1;
        if i == pn { j += 1; continue; }
        if j == qn { i += 1; continue; }
        let order = angle_compare(edge(&p, pn, i), edge(&q, qn, j));
        if order <= 0 { i += 1; }
        if order >= 0 { j += 1; }
    }
    let needed = (1 + 2 * count) * 8;
    if needed > cap || out.is_null() { return -2; }
    let mut offset = 0;
    put_i64(out, &mut offset, count as i64);
    for point in sums.iter().take(count) {
        put_i64(out, &mut offset, point.x);
        put_i64(out, &mut offset, point.y);
    }
    needed as i64
}
