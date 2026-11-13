const MAX_COORDINATE: i64 = 1000;
const MAX_RADIUS: i64 = 1000;

fn classify(x1: i64, y1: i64, r1: i64, x2: i64, y2: i64, r2: i64) i64 {
    const dx = x2 - x1;
    const dy = y2 - y1;
    if (dx == 0 and dy == 0) return if (r1 == r2) 3 else 0;
    const a = -2 * dx;
    const b = -2 * dy;
    const c = dx * dx + dy * dy + r1 * r1 - r2 * r2;
    const discriminant = r1 * r1 * (a * a + b * b) - c * c;
    if (discriminant < 0) return 0;
    return if (discriminant == 0) 1 else 2;
}

export fn circle_circle_intersection_count(input_opt: ?[*]const i64, length: usize) i64 {
    if (input_opt == null or length != 6) return -1;
    const input = input_opt.?;
    const x1 = input[0];
    const y1 = input[1];
    const r1 = input[2];
    const x2 = input[3];
    const y2 = input[4];
    const r2 = input[5];
    if (x1 < -MAX_COORDINATE or x1 > MAX_COORDINATE or
        y1 < -MAX_COORDINATE or y1 > MAX_COORDINATE or
        x2 < -MAX_COORDINATE or x2 > MAX_COORDINATE or
        y2 < -MAX_COORDINATE or y2 > MAX_COORDINATE or
        r1 < 1 or r1 > MAX_RADIUS or r2 < 1 or r2 > MAX_RADIUS) return -1;
    return classify(x1, y1, r1, x2, y2, r2);
}
