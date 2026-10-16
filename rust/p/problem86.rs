const MAX_LIMIT: i64 = 1_000_000;

fn is_square(value: i64) -> bool {
    let mut root = value;
    let mut next = (root + 1) / 2;
    while next < root { root = next; next = (root + value / root) / 2; }
    root * root == value
}

#[no_mangle]
pub extern "C" fn problem86(limit: i64) -> i64 {
    if limit > MAX_LIMIT { return -1; }
    if limit < 0 { return 0; }
    let mut cuboid_count = 0_i64;
    let mut max_side = 0_i64;
    while cuboid_count <= limit {
        max_side += 1;
        for sum_sides in 2..=2 * max_side {
            if !is_square(sum_sides * sum_sides + max_side * max_side) { continue; }
            let high = max_side.min(sum_sides / 2);
            let low = (sum_sides - max_side).max(1);
            cuboid_count += high - low + 1;
        }
    }
    max_side
}
