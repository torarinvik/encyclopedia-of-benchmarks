export fn point_in_polygon_ray_casting(values: [*c]const i64, length: usize) i64 {
    if (values == null or length < 9 or length > 131) return -1;
    const n = values[0];
    if (n < 3 or n > 64 or length != @as(usize, @intCast(3 + 2 * n))) return -1;
    const qx = values[1];
    const qy = values[2];
    const bound: i64 = 1_000_000;
    if (qx < -bound or qx > bound or qy < -bound or qy > bound) return -1;
    for (3..length) |index| {
        if (values[index] < -bound or values[index] > bound) return -1;
    }

    var inside = false;
    const vertex_count: usize = @intCast(n);
    for (0..vertex_count) |i| {
        const j = (i + 1) % vertex_count;
        const ax = values[3 + 2 * i];
        const ay = values[4 + 2 * i];
        const bx = values[3 + 2 * j];
        const by = values[4 + 2 * j];
        const turn = (bx - ax) * (qy - ay) - (by - ay) * (qx - ax);
        if (turn == 0 and qx >= @min(ax, bx) and qx <= @max(ax, bx) and
            qy >= @min(ay, by) and qy <= @max(ay, by)) return 1;
        if ((ay > qy) != (by > qy) and ((by > ay and turn > 0) or (by < ay and turn < 0))) {
            inside = !inside;
        }
    }
    return if (inside) 1 else 0;
}
