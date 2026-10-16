const MAX_LIMIT: i64 = 1_000_000;

fn isSquare(value: i64) bool {
    var root = value;
    var next = @divTrunc(root + 1, 2);
    while (next < root) {
        root = next;
        next = @divTrunc(root + @divTrunc(value, root), 2);
    }
    return root * root == value;
}

export fn problem86(limit: i64) i64 {
    if (limit > MAX_LIMIT) return -1;
    if (limit < 0) return 0;
    var cuboid_count: i64 = 0;
    var max_side: i64 = 0;
    while (cuboid_count <= limit) {
        max_side += 1;
        var sum_sides: i64 = 2;
        while (sum_sides <= 2 * max_side) : (sum_sides += 1) {
            if (!isSquare(sum_sides * sum_sides + max_side * max_side)) continue;
            const high = @min(max_side, @divTrunc(sum_sides, 2));
            const low = @max(@as(i64, 1), sum_sides - max_side);
            cuboid_count += high - low + 1;
        }
    }
    return max_side;
}
