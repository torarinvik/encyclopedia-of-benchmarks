const MAX_POINTS: usize = 32;
const MAX_INPUT_LENGTH: usize = 1 + 2 * MAX_POINTS;
const COORDINATE_LIMIT: i64 = 1_000_000;

export fn manhattan_mst(values: [*]const i64, length: usize) i64 {
    if (length < 1 or length > MAX_INPUT_LENGTH) return -1;
    const count_value = values[0];
    if (count_value < 1 or count_value > MAX_POINTS) return -1;
    const count: usize = @intCast(count_value);
    if (length != 1 + 2 * count) return -1;

    var x: [MAX_POINTS]i64 = undefined;
    var y: [MAX_POINTS]i64 = undefined;
    for (0..count) |point| {
        x[point] = values[1 + 2 * point];
        y[point] = values[2 + 2 * point];
        if (x[point] < -COORDINATE_LIMIT or x[point] > COORDINATE_LIMIT or
            y[point] < -COORDINATE_LIMIT or y[point] > COORDINATE_LIMIT) return -1;
    }

    var in_tree: [MAX_POINTS]bool = @splat(false);
    var has_best: [MAX_POINTS]bool = @splat(false);
    var best: [MAX_POINTS]i64 = @splat(0);
    has_best[0] = true;
    var total: i64 = 0;
    for (0..count) |_| {
        var selected = count;
        for (0..count) |point| {
            if (!in_tree[point] and has_best[point] and
                (selected == count or best[point] < best[selected])) selected = point;
        }
        if (selected == count) return -1;
        in_tree[selected] = true;
        total += best[selected];
        for (0..count) |point| {
            if (in_tree[point]) continue;
            const dx = x[selected] - x[point];
            const dy = y[selected] - y[point];
            const distance = (if (dx < 0) -dx else dx) + (if (dy < 0) -dy else dy);
            if (!has_best[point] or distance < best[point]) {
                has_best[point] = true;
                best[point] = distance;
            }
        }
    }
    return total;
}
