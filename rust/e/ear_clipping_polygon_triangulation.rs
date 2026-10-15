const MAX_VERTICES: usize = 64;

#[derive(Clone, Copy)]
struct Point { x: i64, y: i64 }

fn orient(a: Point, b: Point, c: Point) -> i64 {
    (b.x - a.x) * (c.y - a.y) - (b.y - a.y) * (c.x - a.x)
}

fn on_segment(a: Point, b: Point, p: Point) -> bool {
    orient(a, b, p) == 0 && p.x >= a.x.min(b.x) && p.x <= a.x.max(b.x) &&
        p.y >= a.y.min(b.y) && p.y <= a.y.max(b.y)
}

fn segments_intersect(a: Point, b: Point, c: Point, d: Point) -> bool {
    let ab_c = orient(a, b, c);
    let ab_d = orient(a, b, d);
    let cd_a = orient(c, d, a);
    let cd_b = orient(c, d, b);
    if ab_c == 0 && on_segment(a, b, c) { return true; }
    if ab_d == 0 && on_segment(a, b, d) { return true; }
    if cd_a == 0 && on_segment(c, d, a) { return true; }
    if cd_b == 0 && on_segment(c, d, b) { return true; }
    (ab_c < 0) != (ab_d < 0) && (cd_a < 0) != (cd_b < 0)
}

fn in_or_on_triangle(a: Point, b: Point, c: Point, p: Point, winding: i64) -> bool {
    let ab = orient(a, b, p) * winding;
    let bc = orient(b, c, p) * winding;
    let ca = orient(c, a, p) * winding;
    ab >= 0 && bc >= 0 && ca >= 0
}

unsafe fn emit_triangle(output: *mut u8, position: usize, a: usize, b: usize, c: usize) {
    for (slot, value) in [a, b, c].iter().enumerate() {
        let bytes = (*value as u32).to_le_bytes();
        for byte in 0..4 { *output.add(position * 12 + slot * 4 + byte) = bytes[byte]; }
    }
}

#[no_mangle]
pub unsafe extern "C" fn ear_clipping_polygon_triangulation(
    values: *const i64, length: usize, output: *mut u8, output_capacity: usize,
) -> i64 {
    if length < 6 || length > MAX_VERTICES * 2 || length % 2 != 0 || values.is_null() { return -1; }
    let n = length / 2;
    let mut points = [Point { x: 0, y: 0 }; MAX_VERTICES];
    for i in 0..n {
        let x = *values.add(2 * i);
        let y = *values.add(2 * i + 1);
        if !(-10_000..=10_000).contains(&x) || !(-10_000..=10_000).contains(&y) { return -1; }
        points[i] = Point { x, y };
        for prior in 0..i {
            if points[prior].x == x && points[prior].y == y { return -1; }
        }
    }
    let mut twice_area = 0_i64;
    for i in 0..n {
        let next = (i + 1) % n;
        let after = (i + 2) % n;
        if orient(points[i], points[next], points[after]) == 0 { return -1; }
        twice_area += points[i].x * points[next].y - points[i].y * points[next].x;
    }
    if twice_area == 0 { return -1; }
    for i in 0..n {
        let i_next = (i + 1) % n;
        for j in (i + 1)..n {
            let j_next = (j + 1) % n;
            if i == j || i_next == j || j_next == i { continue; }
            if segments_intersect(points[i], points[i_next], points[j], points[j_next]) { return -1; }
        }
    }
    let required = 12 * (n - 2);
    if output.is_null() || output_capacity < required { return -2; }

    let winding = if twice_area > 0 { 1 } else { -1 };
    let mut live = [false; MAX_VERTICES];
    for i in 0..n { live[i] = true; }
    let mut remaining = n;
    let mut emitted = 0;
    while remaining > 3 {
        let mut found = false;
        for current in 0..n {
            if !live[current] { continue; }
            let mut previous = (current + n - 1) % n;
            while !live[previous] { previous = (previous + n - 1) % n; }
            let mut next = (current + 1) % n;
            while !live[next] { next = (next + 1) % n; }
            if orient(points[previous], points[current], points[next]) * winding <= 0 { continue; }
            let mut blocked = false;
            for candidate in 0..n {
                if live[candidate] && candidate != previous && candidate != current && candidate != next &&
                    in_or_on_triangle(points[previous], points[current], points[next], points[candidate], winding) {
                    blocked = true;
                    break;
                }
            }
            if blocked { continue; }
            emit_triangle(output, emitted, previous, current, next);
            emitted += 1;
            live[current] = false;
            remaining -= 1;
            found = true;
            break;
        }
        if !found { return -1; }
    }
    let mut final_ids = [0_usize; 3];
    let mut final_count = 0;
    for i in 0..n {
        if live[i] { final_ids[final_count] = i; final_count += 1; }
    }
    if final_count != 3 { return -1; }
    emit_triangle(output, emitted, final_ids[0], final_ids[1], final_ids[2]);
    (n - 2) as i64
}
