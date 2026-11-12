#[no_mangle]
pub unsafe extern "C" fn point_in_polygon_ray_casting(values: *const i64, length: usize) -> i64 {
    if values.is_null() || !(9..=131).contains(&length) { return -1; }
    let input = std::slice::from_raw_parts(values, length);
    let n = input[0];
    if !(3..=64).contains(&n) || length != (3 + 2 * n) as usize { return -1; }
    let (qx, qy) = (input[1], input[2]);
    const BOUND: i64 = 1_000_000;
    if !(-BOUND..=BOUND).contains(&qx) || !(-BOUND..=BOUND).contains(&qy) { return -1; }
    if input[3..].iter().any(|&value| !(-BOUND..=BOUND).contains(&value)) { return -1; }

    let mut inside = false;
    for i in 0..n as usize {
        let j = (i + 1) % n as usize;
        let (ax, ay) = (input[3 + 2 * i], input[4 + 2 * i]);
        let (bx, by) = (input[3 + 2 * j], input[4 + 2 * j]);
        let turn = (bx - ax) * (qy - ay) - (by - ay) * (qx - ax);
        if turn == 0 && qx >= ax.min(bx) && qx <= ax.max(bx) &&
            qy >= ay.min(by) && qy <= ay.max(by) { return 1; }
        if (ay > qy) != (by > qy) && ((by > ay && turn > 0) || (by < ay && turn < 0)) {
            inside = !inside;
        }
    }
    i64::from(inside)
}
