const MAX_COORDINATE: i64 = 32;
const INVALID_RESULT: f64 = -1.0e300;

export fn circle_polygon_intersection_area(input: ?[*]const i64, length: usize) f64 {
    if (input == null or length < 10 or length > 37) return INVALID_RESULT;
    const values = input.?[0..length];
    const n_value = values[0];
    const cx = values[1];
    const cy = values[2];
    const radius_value = values[3];
    if (n_value < 3 or n_value > 16) return INVALID_RESULT;
    if (length != @as(usize, @intCast(4 + 2 * n_value))) return INVALID_RESULT;
    if (cx < -MAX_COORDINATE or cx > MAX_COORDINATE or cy < -MAX_COORDINATE or cy > MAX_COORDINATE or
        radius_value < 1 or radius_value > MAX_COORDINATE) return INVALID_RESULT;
    const n: usize = @intCast(n_value);
    for (0..n) |i| {
        const x = values[4 + 2 * i];
        const y = values[5 + 2 * i];
        if (x < -MAX_COORDINATE or x > MAX_COORDINATE or y < -MAX_COORDINATE or y > MAX_COORDINATE) return INVALID_RESULT;
    }
    for (0..n) |i| {
        const next = (i + 1) % n;
        const x = values[4 + 2 * i];
        const y = values[5 + 2 * i];
        const dx = values[4 + 2 * next] - x;
        const dy = values[5 + 2 * next] - y;
        for (0..n) |j| {
            if (j == i or j == next) continue;
            if (dx * (values[5 + 2 * j] - y) - dy * (values[4 + 2 * j] - x) <= 0) return INVALID_RESULT;
        }
        if (dx * (cy - y) - dy * (cx - x) <= 0) return INVALID_RESULT;
    }

    const radius: f64 = @floatFromInt(radius_value);
    const radius_squared = radius * radius;
    var doubled_area: f64 = 0.0;
    for (0..n) |i| {
        const next = (i + 1) % n;
        const px: f64 = @floatFromInt(values[4 + 2 * i] - cx);
        const py: f64 = @floatFromInt(values[5 + 2 * i] - cy);
        const qx: f64 = @floatFromInt(values[4 + 2 * next] - cx);
        const qy: f64 = @floatFromInt(values[5 + 2 * next] - cy);
        const dx = qx - px;
        const dy = qy - py;
        const edge_squared = dx * dx + dy * dy;
        const projection = px * dx + py * dy;
        const constant = px * px + py * py - radius_squared;
        const discriminant = projection * projection - edge_squared * constant;
        const full_angle = @atan2(px * qy - py * qx, px * qx + py * qy);
        if (discriminant <= 0.0) {
            doubled_area += radius_squared * full_angle;
            continue;
        }
        const root = @sqrt(discriminant);
        const first = (-projection - root) / edge_squared;
        const second = (-projection + root) / edge_squared;
        if (second < 0.0 or first > 1.0) {
            doubled_area += radius_squared * full_angle;
            continue;
        }
        const start = @max(0.0, first);
        const stop = @min(1.0, second);
        const ux = px + start * dx;
        const uy = py + start * dy;
        const vx = px + stop * dx;
        const vy = py + stop * dy;
        const first_angle = @atan2(px * uy - py * ux, px * ux + py * uy);
        const last_angle = @atan2(vx * qy - vy * qx, vx * qx + vy * qy);
        doubled_area += radius_squared * (first_angle + last_angle) + ux * vy - uy * vx;
    }
    return 0.5 * doubled_area;
}
