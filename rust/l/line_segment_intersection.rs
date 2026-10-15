const COORDINATE_LIMIT: i64 = 10_000;

#[derive(Clone, Copy)]
struct Point { x: i64, y: i64 }

fn orient(a: Point, b: Point, c: Point) -> i64 {
    (b.x - a.x) * (c.y - a.y) - (b.y - a.y) * (c.x - a.x)
}

fn on_segment(a: Point, b: Point, p: Point) -> bool {
    a.x.min(b.x) <= p.x && p.x <= a.x.max(b.x) &&
        a.y.min(b.y) <= p.y && p.y <= a.y.max(b.y)
}

#[no_mangle]
pub unsafe extern "C" fn line_segment_intersection(
    values: *const i64, length: usize, _output: *mut u8, _output_capacity: usize,
) -> i64 {
    if length != 8 || values.is_null() { return -1; }
    let input = std::slice::from_raw_parts(values, length);
    if input.iter().any(|value| !(-COORDINATE_LIMIT..=COORDINATE_LIMIT).contains(value)) {
        return -1;
    }
    let a = Point { x: input[0], y: input[1] };
    let b = Point { x: input[2], y: input[3] };
    let c = Point { x: input[4], y: input[5] };
    let d = Point { x: input[6], y: input[7] };
    let ab_c = orient(a, b, c);
    let ab_d = orient(a, b, d);
    let cd_a = orient(c, d, a);
    let cd_b = orient(c, d, b);

    if ab_c == 0 && on_segment(a, b, c) { return 1; }
    if ab_d == 0 && on_segment(a, b, d) { return 1; }
    if cd_a == 0 && on_segment(c, d, a) { return 1; }
    if cd_b == 0 && on_segment(c, d, b) { return 1; }
    if ((ab_c > 0 && ab_d < 0) || (ab_c < 0 && ab_d > 0)) &&
        ((cd_a > 0 && cd_b < 0) || (cd_a < 0 && cd_b > 0)) {
        return 1;
    }
    0
}
