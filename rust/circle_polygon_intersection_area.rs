use std::slice;

const INVALID_RESULT: f64 = -1.0e300;
const MAX_COORDINATE: i64 = 32;

#[no_mangle]
pub unsafe extern "C" fn circle_polygon_intersection_area(input: *const i64, length: usize) -> f64 {
    if input.is_null() || !(10..=37).contains(&length) { return INVALID_RESULT; }
    let values = slice::from_raw_parts(input, length);
    let (n_value, cx, cy, radius_value) = (values[0], values[1], values[2], values[3]);
    if !(3..=16).contains(&n_value) { return INVALID_RESULT; }
    if length != (4 + 2 * n_value) as usize { return INVALID_RESULT; }
    if !(-MAX_COORDINATE..=MAX_COORDINATE).contains(&cx) ||
       !(-MAX_COORDINATE..=MAX_COORDINATE).contains(&cy) ||
       !(1..=MAX_COORDINATE).contains(&radius_value) { return INVALID_RESULT; }
    let n = n_value as usize;
    for index in 0..n {
        let x = values[4 + 2 * index];
        let y = values[5 + 2 * index];
        if !(-MAX_COORDINATE..=MAX_COORDINATE).contains(&x) ||
           !(-MAX_COORDINATE..=MAX_COORDINATE).contains(&y) { return INVALID_RESULT; }
    }
    for index in 0..n {
        let next = (index + 1) % n;
        let x = values[4 + 2 * index];
        let y = values[5 + 2 * index];
        let dx = values[4 + 2 * next] - x;
        let dy = values[5 + 2 * next] - y;
        for other in 0..n {
            if other == index || other == next { continue; }
            let side = dx * (values[5 + 2 * other] - y) - dy * (values[4 + 2 * other] - x);
            if side <= 0 { return INVALID_RESULT; }
        }
        if dx * (cy - y) - dy * (cx - x) <= 0 { return INVALID_RESULT; }
    }

    let radius = radius_value as f64;
    let radius_squared = radius * radius;
    let mut doubled_area = 0.0;
    for index in 0..n {
        let next = (index + 1) % n;
        let px = (values[4 + 2 * index] - cx) as f64;
        let py = (values[5 + 2 * index] - cy) as f64;
        let qx = (values[4 + 2 * next] - cx) as f64;
        let qy = (values[5 + 2 * next] - cy) as f64;
        let dx = qx - px;
        let dy = qy - py;
        let edge_squared = dx * dx + dy * dy;
        let projection = px * dx + py * dy;
        let constant = px * px + py * py - radius_squared;
        let discriminant = projection * projection - edge_squared * constant;
        let full_angle = (px * qy - py * qx).atan2(px * qx + py * qy);
        if discriminant <= 0.0 {
            doubled_area += radius_squared * full_angle;
            continue;
        }
        let root = discriminant.sqrt();
        let first = (-projection - root) / edge_squared;
        let second = (-projection + root) / edge_squared;
        if second < 0.0 || first > 1.0 {
            doubled_area += radius_squared * full_angle;
            continue;
        }
        let start = first.max(0.0);
        let stop = second.min(1.0);
        let ux = px + start * dx;
        let uy = py + start * dy;
        let vx = px + stop * dx;
        let vy = py + stop * dy;
        let first_angle = (px * uy - py * ux).atan2(px * ux + py * uy);
        let last_angle = (vx * qy - vy * qx).atan2(vx * qx + vy * qy);
        doubled_area += radius_squared * (first_angle + last_angle) + ux * vy - uy * vx;
    }
    0.5 * doubled_area
}
