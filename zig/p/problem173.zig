/// Count square laminae using at most max_tiles tiles.
const MAX_TILES: i64 = 1_000_000;

fn problem173CeilSqrt(value: i64) i64 {
    if (value <= 0) return 0;
    var root = value;
    var next = @divTrunc(root + @divTrunc(value, root), 2);
    while (next < root) {
        root = next;
        next = @divTrunc(root + @divTrunc(value, root), 2);
    }
    return if (root * root == value) root else root + 1;
}

export fn problem173(max_tiles: i64) i64 {
    if (max_tiles < 0 or max_tiles > MAX_TILES) return -1;
    var answer: i64 = 0;
    var outer_width: i64 = 3;
    while (outer_width < @divTrunc(max_tiles, 4) + 2) {
        var hole_width: i64 = 1;
        const outer_area = outer_width * outer_width;
        if (outer_area > max_tiles) {
            hole_width = problem173CeilSqrt(outer_area - max_tiles);
            if (hole_width < 1) hole_width = 1;
        }
        if (@rem(outer_width - hole_width, 2) != 0) hole_width += 1;
        answer += @divTrunc(outer_width - hole_width - 2, 2) + 1;
        outer_width += 1;
    }
    return answer;
}
