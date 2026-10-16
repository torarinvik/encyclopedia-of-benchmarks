const MAX_TILES: i64 = 1_000_000;

fn ceil_sqrt(value: i64) -> i64 {
    if value <= 0 { return 0; }
    let mut root = value;
    let mut next = (root + value / root) / 2;
    while next < root {
        root = next;
        next = (root + value / root) / 2;
    }
    if root * root == value { root } else { root + 1 }
}

#[no_mangle]
pub extern "C" fn problem174(t_limit: i64, n_limit: i64) -> i64 {
    if t_limit > MAX_TILES { return -1; }
    if t_limit < 0 { return 0; }
    let bound = t_limit as usize;
    let mut count = vec![0_u8; bound + 1];
    let mut outer_width = 3_i64;
    while outer_width < t_limit / 4 + 2 {
        let outer_area = outer_width * outer_width;
        let mut hole_lower = 1_i64;
        if outer_area > t_limit {
            hole_lower = ceil_sqrt(outer_area - t_limit);
            if hole_lower < 1 { hole_lower = 1; }
        }
        if (outer_width - hole_lower) % 2 != 0 { hole_lower += 1; }
        let mut hole_width = hole_lower;
        while hole_width < outer_width - 1 {
            let tiles = (outer_area - hole_width * hole_width) as usize;
            count[tiles] += 1;
            hole_width += 2;
        }
        outer_width += 1;
    }
    count.iter().skip(1).filter(|&&representations| representations >= 1 && i64::from(representations) <= n_limit).count() as i64
}
