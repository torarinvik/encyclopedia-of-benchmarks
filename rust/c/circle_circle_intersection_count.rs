const MAX_COORDINATE: i64 = 1_000;
const MAX_RADIUS: i64 = 1_000;

fn classify(x1: i64, y1: i64, r1: i64, x2: i64, y2: i64, r2: i64) -> i64 {
    let dx = x2 - x1;
    let dy = y2 - y1;
    if dx == 0 && dy == 0 { return if r1 == r2 { 3 } else { 0 }; }
    let a = -2 * dx;
    let b = -2 * dy;
    let c = dx * dx + dy * dy + r1 * r1 - r2 * r2;
    let discriminant = r1 * r1 * (a * a + b * b) - c * c;
    if discriminant < 0 { return 0; }
    if discriminant == 0 { return 1; }
    2
}

#[no_mangle]
pub unsafe extern "C" fn circle_circle_intersection_count(
    input: *const i64,
    length: usize,
) -> i64 {
    if input.is_null() || length != 6 { return -1; }
    let values = std::slice::from_raw_parts(input, length);
    let x1 = values[0];
    let y1 = values[1];
    let r1 = values[2];
    let x2 = values[3];
    let y2 = values[4];
    let r2 = values[5];
    if x1 < -MAX_COORDINATE || x1 > MAX_COORDINATE ||
        y1 < -MAX_COORDINATE || y1 > MAX_COORDINATE ||
        x2 < -MAX_COORDINATE || x2 > MAX_COORDINATE ||
        y2 < -MAX_COORDINATE || y2 > MAX_COORDINATE ||
        r1 < 1 || r1 > MAX_RADIUS || r2 < 1 || r2 > MAX_RADIUS { return -1; }
    classify(x1, y1, r1, x2, y2, r2)
}
