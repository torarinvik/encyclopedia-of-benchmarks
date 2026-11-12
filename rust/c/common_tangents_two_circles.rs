const MAX_COORDINATE: i64 = 100_000;
const MAX_RADIUS: i64 = 100_000;

fn count_tangents(x1: i64, y1: i64, r1: i64, x2: i64, y2: i64, r2: i64) -> i64 {
    let dx = x2 - x1;
    let dy = y2 - y1;
    let distance_squared = dx * dx + dy * dy;
    let signs = [-1i64, 1i64];
    let mut candidates = 0i64;
    for first_sign in signs {
        for second_sign in signs {
            let difference = second_sign * r2 - first_sign * r1;
            if distance_squared >= difference * difference { candidates += 1; }
        }
    }
    if r1 == 0 && r2 == 0 { return 1; }
    if r1 == 0 || r2 == 0 {
        let radius = r1 + r2;
        return if distance_squared == radius * radius { 1 } else { candidates / 2 };
    }
    let radius_sum = r1 + r2;
    let radius_difference = r1 - r2;
    if distance_squared == radius_sum * radius_sum || distance_squared == radius_difference * radius_difference {
        candidates -= 1;
    }
    candidates
}

#[no_mangle]
pub unsafe extern "C" fn common_tangents_two_circles(input: *const i64, length: usize) -> i64 {
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
        r1 < 0 || r1 > MAX_RADIUS || r2 < 0 || r2 > MAX_RADIUS ||
        (x1 == x2 && y1 == y2) { return -1; }
    count_tangents(x1, y1, r1, x2, y2, r2)
}
