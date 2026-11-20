const MAX_COORDINATE: i64 = 1_000_000_000;

fn solve(input: &[i64]) -> i64 {
    if input.len() != 2 { return -1; }
    let (dx, dy) = (input[0], input[1]);
    if dx < -MAX_COORDINATE || dx > MAX_COORDINATE
        || dy < -MAX_COORDINATE || dy > MAX_COORDINATE
    {
        return -1;
    }
    let (abs_x, abs_y) = (dx.abs(), dy.abs());
    let large = abs_x.max(abs_y);
    let small = abs_x.min(abs_y);
    if large == 1 && small == 0 { return 3; }
    if large == 2 && small == 2 { return 4; }
    let mut distance = (large + 1) / 2;
    distance = distance.max((large + small + 2) / 3);
    if (large + small - distance) % 2 != 0 { distance += 1; }
    distance
}

#[no_mangle]
pub unsafe extern "C" fn infinite_knight_distance(input: *const i64, length: usize) -> i64 {
    if input.is_null() || length != 2 { return -1; }
    solve(std::slice::from_raw_parts(input, length))
}
