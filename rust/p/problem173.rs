/// Count square laminae using at most max_tiles tiles.
const MAX_TILES: i64 = 1_000_000;

fn problem173_ceil_sqrt(value: i64) -> i64 {
    if value <= 0 {
        return 0;
    }
    let mut root = value;
    let mut next = (root + value / root) / 2;
    while next < root {
        root = next;
        next = (root + value / root) / 2;
    }
    if root * root == value { root } else { root + 1 }
}

#[no_mangle]
pub extern "C" fn problem173(max_tiles: i64) -> i64 {
    if max_tiles < 0 || max_tiles > MAX_TILES {
        return -1;
    }
    let mut answer = 0i64;
    let mut outer_width = 3i64;
    while outer_width < max_tiles / 4 + 2 {
        let mut hole_width = 1i64;
        let outer_area = outer_width * outer_width;
        if outer_area > max_tiles {
            hole_width = problem173_ceil_sqrt(outer_area - max_tiles);
            if hole_width < 1 { hole_width = 1; }
        }
        if (outer_width - hole_width) % 2 != 0 { hole_width += 1; }
        answer += (outer_width - hole_width - 2) / 2 + 1;
        outer_width += 1;
    }
    answer
}
