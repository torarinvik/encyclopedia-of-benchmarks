const MAX_N: usize = 16;

export fn minimum_area_rectangle_arbitrary_orientation(input_opt: ?[*]const i64, length: usize) i64 {
    if (input_opt == null or length == 0 or length > 34) return -1;
    const input = input_opt.?;
    const n_value = input[0];
    if (n_value < 4 or n_value > 16) return -1;
    const n: usize = @intCast(n_value);
    if (length != 1 + 2 * n) return -1;

    var x: [MAX_N]i64 = @splat(0);
    var y: [MAX_N]i64 = @splat(0);
    for (0..n) |i| {
        x[i] = input[1 + 2 * i];
        y[i] = input[2 + 2 * i];
        if (x[i] < -32 or x[i] > 32 or y[i] < -32 or y[i] > 32) return -1;
        for (0..i) |j| if (x[i] == x[j] and y[i] == y[j]) { return -1; };
    }

    var best: i64 = -1;
    for (0..n) |i| {
        for (i + 1..n) |j| {
            const dx1 = x[i] - x[j];
            const dy1 = y[i] - y[j];
            const mid_x = x[i] + x[j];
            const mid_y = y[i] + y[j];
            const len1 = dx1 * dx1 + dy1 * dy1;
            for (0..n) |k| {
                for (k + 1..n) |l| {
                    if (k < i or (k == i and l <= j)) continue;
                    if (k == i or k == j or l == i or l == j) continue;
                    if (mid_x != x[k] + x[l] or mid_y != y[k] + y[l]) continue;
                    const dx2 = x[k] - x[l];
                    const dy2 = y[k] - y[l];
                    if (len1 != dx2 * dx2 + dy2 * dy2) continue;
                    const cross = dx1 * dy2 - dy1 * dx2;
                    const area2 = if (cross < 0) -cross else cross;
                    if (best < 0 or area2 < best) best = area2;
                }
            }
        }
    }
    return if (best < 0) 0 else best;
}
