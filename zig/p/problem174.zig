const std = @import("std");
const MAX_TILES: i64 = 1_000_000;

fn ceilSqrt(value: i64) i64 {
    if (value <= 0) return 0;
    var root = value;
    var next = @divTrunc(root + @divTrunc(value, root), 2);
    while (next < root) {
        root = next;
        next = @divTrunc(root + @divTrunc(value, root), 2);
    }
    return if (root * root == value) root else root + 1;
}

export fn problem174(t_limit: i64, n_limit: i64) i64 {
    if (t_limit > MAX_TILES) return -1;
    if (t_limit < 0) return 0;
    const bound: usize = @intCast(t_limit);
    const count = std.heap.page_allocator.alloc(u8, bound + 1) catch return -1;
    defer std.heap.page_allocator.free(count);
    @memset(count, 0);
    var outer_width: i64 = 3;
    while (outer_width < @divTrunc(t_limit, 4) + 2) : (outer_width += 1) {
        const outer_area = outer_width * outer_width;
        var hole_lower: i64 = 1;
        if (outer_area > t_limit) {
            hole_lower = ceilSqrt(outer_area - t_limit);
            if (hole_lower < 1) hole_lower = 1;
        }
        if (@rem(outer_width - hole_lower, 2) != 0) hole_lower += 1;
        var hole_width = hole_lower;
        while (hole_width < outer_width - 1) : (hole_width += 2) {
            const tiles: usize = @intCast(outer_area - hole_width * hole_width);
            count[tiles] += 1;
        }
    }
    var answer: i64 = 0;
    for (1..bound + 1) |tiles| {
        if (count[tiles] >= 1 and @as(i64, count[tiles]) <= n_limit) answer += 1;
    }
    return answer;
}
