const COORDINATE_LIMIT: i64 = 10_000;
#[derive(Clone, Copy)]
struct Point { x: i64, y: i64 }
fn same(a: Point, b: Point) -> bool { a.x == b.x && a.y == b.y }
fn cross(a: Point, b: Point, c: Point) -> i64 {
    (b.x - a.x) * (c.y - a.y) - (b.y - a.y) * (c.x - a.x)
}
fn on_segment(a: Point, b: Point, p: Point) -> bool {
    cross(a, b, p) == 0 && a.x.min(b.x) <= p.x && p.x <= a.x.max(b.x) &&
        a.y.min(b.y) <= p.y && p.y <= a.y.max(b.y)
}
unsafe fn write_point(output: *mut u8, capacity: usize, x: f64, y: f64) -> i64 {
    if output.is_null() || capacity < 16 { return -2; }
    let x_bytes = x.to_le_bytes();
    let y_bytes = y.to_le_bytes();
    for index in 0..8 { *output.add(index) = x_bytes[index]; *output.add(8 + index) = y_bytes[index]; }
    1
}

#[no_mangle]
pub unsafe extern "C" fn line_intersection(
    values: *const i64, length: usize, output: *mut u8, output_capacity: usize,
) -> i64 {
    if length != 9 || values.is_null() { return -1; }
    let mut input = [0_i64; 9];
    for index in 0..9 { input[index] = *values.add(index); }
    if input[..8].iter().any(|value| !(-COORDINATE_LIMIT..=COORDINATE_LIMIT).contains(value)) ||
        (input[8] != 0 && input[8] != 1) { return -1; }
    let p1 = Point { x: input[0], y: input[1] };
    let p2 = Point { x: input[2], y: input[3] };
    let q1 = Point { x: input[4], y: input[5] };
    let q2 = Point { x: input[6], y: input[7] };
    let segments = input[8] == 1;
    let p_point = same(p1, p2);
    let q_point = same(q1, q2);
    if !segments && (p_point || q_point) { return -1; }
    if segments && p_point && q_point {
        return if same(p1, q1) { write_point(output, output_capacity, p1.x as f64, p1.y as f64) } else { 0 };
    }
    if segments && p_point {
        return if on_segment(q1, q2, p1) { write_point(output, output_capacity, p1.x as f64, p1.y as f64) } else { 0 };
    }
    if segments && q_point {
        return if on_segment(p1, p2, q1) { write_point(output, output_capacity, q1.x as f64, q1.y as f64) } else { 0 };
    }
    let denominator = (p1.x - p2.x) * (q1.y - q2.y) - (p1.y - p2.y) * (q1.x - q2.x);
    if denominator == 0 { return 0; }
    let determinant_p = p1.x * p2.y - p1.y * p2.x;
    let determinant_q = q1.x * q2.y - q1.y * q2.x;
    let numerator_x = determinant_p * (q1.x - q2.x) - (p1.x - p2.x) * determinant_q;
    let numerator_y = determinant_p * (q1.y - q2.y) - (p1.y - p2.y) * determinant_q;
    if segments {
        let den = denominator.abs();
        let x = if denominator < 0 { -numerator_x } else { numerator_x };
        let y = if denominator < 0 { -numerator_y } else { numerator_y };
        let min_x = p1.x.min(p2.x).max(q1.x.min(q2.x));
        let max_x = p1.x.max(p2.x).min(q1.x.max(q2.x));
        let min_y = p1.y.min(p2.y).max(q1.y.min(q2.y));
        let max_y = p1.y.max(p2.y).min(q1.y.max(q2.y));
        if x < min_x * den || x > max_x * den || y < min_y * den || y > max_y * den { return 0; }
        return write_point(output, output_capacity, x as f64 / den as f64, y as f64 / den as f64);
    }
    write_point(output, output_capacity, numerator_x as f64 / denominator as f64,
                numerator_y as f64 / denominator as f64)
}
