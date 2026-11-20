const MAX_VERTICES: usize = 32;
const MAX_QUERIES: usize = 16;
const MAX_INPUT: usize = 99;
const MAX_COORDINATE: i64 = 1000;

#[derive(Clone, Copy, Default)]
struct Point { x: i64, y: i64 }

fn sub(a: Point, b: Point) -> Point { Point { x: a.x - b.x, y: a.y - b.y } }
fn cross(a: Point, b: Point) -> i64 { a.x * b.y - a.y * b.x }

fn valid_polygon(p: &[Point], n: usize) -> bool {
    for i in 0..n {
        let next = (i + 1) % n;
        if p[i].x == p[next].x && p[i].y == p[next].y { return false; }
        let edge = sub(p[next], p[i]);
        for j in 0..n {
            if j != i && j != next && cross(edge, sub(p[j], p[i])) <= 0 { return false; }
        }
    }
    true
}

fn valid_query(p: &[Point], q: Point) -> bool {
    let mut outside = false;
    for i in 0..p.len() {
        let side = cross(sub(p[(i + 1) % p.len()], p[i]), sub(q, p[i]));
        if side == 0 { return false; }
        if side < 0 { outside = true; }
    }
    outside
}

fn build_chain(chain: &mut [usize; MAX_VERTICES], n: usize, start: usize, stop: usize) -> usize {
    let (mut length, mut at) = (0, start);
    loop {
        if length >= n { return 0; }
        chain[length] = at;
        length += 1;
        if at == stop { return length; }
        at = (at + 1) % n;
    }
}

fn build_layers(p: &[Point], lower: &mut [usize; MAX_VERTICES],
                upper: &mut [usize; MAX_VERTICES]) -> Option<(usize, usize)> {
    let n = p.len();
    let mut min_x = 0usize;
    let mut max_x = 0usize;
    for i in 1..n {
        if p[i].x < p[min_x].x { min_x = i; }
        if p[i].x > p[max_x].x { max_x = i; }
    }
    let (mut left_bottom, mut left_top, mut right_bottom, mut right_top) =
        (min_x, min_x, max_x, max_x);
    for i in 0..n {
        if p[i].x == p[min_x].x {
            if p[i].y < p[left_bottom].y { left_bottom = i; }
            if p[i].y > p[left_top].y { left_top = i; }
        }
        if p[i].x == p[max_x].x {
            if p[i].y < p[right_bottom].y { right_bottom = i; }
            if p[i].y > p[right_top].y { right_top = i; }
        }
    }
    let lower_len = build_chain(lower, n, left_bottom, right_bottom);
    let upper_len = build_chain(upper, n, right_top, left_top);
    if lower_len == 0 || upper_len == 0 { None } else { Some((lower_len, upper_len)) }
}

fn split_ascending(p: &[Point], chain: &[usize], qx: i64) -> isize {
    let (mut lo, mut hi) = (0usize, chain.len());
    while lo < hi {
        let mid = lo + (hi - lo) / 2;
        if p[chain[mid]].x < qx { lo = mid + 1; } else { hi = mid; }
    }
    if lo == 0 { 0 } else { (lo - 1) as isize }
}

fn split_descending(p: &[Point], chain: &[usize], qx: i64) -> isize {
    let (mut lo, mut hi) = (0usize, chain.len());
    while lo < hi {
        let mid = lo + (hi - lo) / 2;
        if p[chain[mid]].x > qx { lo = mid + 1; } else { hi = mid; }
    }
    if lo == 0 { 0 } else { (lo - 1) as isize }
}

fn tangent_search(p: &[Point], chain: &[usize], mut lo: isize, mut hi: isize,
                  q: Point, sign: i64) -> usize {
    let mut result = lo;
    while lo <= hi {
        let mid = lo + (hi - lo) / 2;
        let index = chain[mid as usize];
        let here = sub(p[index], q);
        let to_next = sign * cross(here, sub(p[(index + 1) % p.len()], q));
        let to_prev = sign * cross(here, sub(p[(index + p.len() - 1) % p.len()], q));
        if to_next >= 0 && to_prev >= 0 { return mid as usize; }
        if to_next >= 0 { result = mid; hi = mid - 1; }
        else { lo = mid + 1; }
    }
    result as usize
}

fn supports(p: &[Point], index: usize, q: Point, sign: i64) -> bool {
    let here = sub(p[index], q);
    sign * cross(here, sub(p[(index + p.len() - 1) % p.len()], q)) > 0 &&
        sign * cross(here, sub(p[(index + 1) % p.len()], q)) > 0
}

fn find_tangents(p: &[Point], lower: &[usize], upper: &[usize], q: Point) -> Option<(i64, i64)> {
    let lower_split = split_ascending(p, lower, q.x);
    let upper_split = split_descending(p, upper, q.x);
    let left_a = lower[tangent_search(p, lower, 0, lower_split, q, -1)];
    let left_b = upper[tangent_search(p, upper, 0, upper_split, q, -1)];
    let right_a = lower[tangent_search(p, lower, lower_split, lower.len() as isize - 1, q, 1)];
    let right_b = upper[tangent_search(p, upper, upper_split, upper.len() as isize - 1, q, 1)];
    let left = if supports(p, left_a, q, -1) { Some(left_a) }
        else if supports(p, left_b, q, -1) { Some(left_b) } else { None }?;
    let right = if supports(p, right_a, q, 1) { Some(right_a) }
        else if supports(p, right_b, q, 1) { Some(right_b) } else { None }?;
    if left == right { return None; }
    Some((left.min(right) as i64, left.max(right) as i64))
}

unsafe fn put_i64(out: *mut u8, offset: usize, value: i64) {
    for (b, byte) in value.to_le_bytes().iter().enumerate() { *out.add(offset + b) = *byte; }
}

#[no_mangle]
pub unsafe extern "C" fn external_point_tangents_convex_polygon(
    v: *const i64, length: usize, out: *mut u8, capacity: usize,
) -> i64 {
    if v.is_null() || length < 2 || length > MAX_INPUT { return -1; }
    let input = std::slice::from_raw_parts(v, length);
    if !(3..=MAX_VERTICES as i64).contains(&input[0]) || !(0..=MAX_QUERIES as i64).contains(&input[1]) { return -1; }
    let (n, q_count) = (input[0] as usize, input[1] as usize);
    if length != 2 + 2 * n + 2 * q_count { return -1; }
    let mut polygon = [Point::default(); MAX_VERTICES];
    let mut queries = [Point::default(); MAX_QUERIES];
    let mut answers = [0i64; 2 * MAX_QUERIES];
    let mut at = 2;
    for point in polygon.iter_mut().take(n) {
        *point = Point { x: input[at], y: input[at + 1] }; at += 2;
        if point.x < -MAX_COORDINATE || point.x > MAX_COORDINATE ||
            point.y < -MAX_COORDINATE || point.y > MAX_COORDINATE { return -1; }
    }
    if !valid_polygon(&polygon[..n], n) { return -1; }
    let mut lower_storage = [0usize; MAX_VERTICES];
    let mut upper_storage = [0usize; MAX_VERTICES];
    let Some((lower_len, upper_len)) = build_layers(&polygon[..n], &mut lower_storage, &mut upper_storage) else { return -1; };
    let lower = &lower_storage[..lower_len];
    let upper = &upper_storage[..upper_len];
    for i in 0..q_count {
        queries[i] = Point { x: input[at], y: input[at + 1] }; at += 2;
        if queries[i].x < -MAX_COORDINATE || queries[i].x > MAX_COORDINATE ||
            queries[i].y < -MAX_COORDINATE || queries[i].y > MAX_COORDINATE ||
            !valid_query(&polygon[..n], queries[i]) { return -1; }
        let Some((first, second)) = find_tangents(&polygon[..n], lower, upper, queries[i]) else { return -1; };
        answers[2 * i] = first;
        answers[2 * i + 1] = second;
    }
    let needed = 16 * q_count;
    if needed > capacity || out.is_null() { return -2; }
    for (i, answer) in answers.iter().take(2 * q_count).enumerate() { put_i64(out, 8 * i, *answer); }
    needed as i64
}
