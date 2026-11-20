const SCALE: i64 = 86_093_442;
const INF: i64 = 1 << 60;
const MAX_N: usize = 8;
const MAX_INPUT: usize = 93;

fn evenIndex(x: usize, threshold: i64, nearest: *const [32]usize, distance: *const [64]i64) usize {
    return if (distance[x * MAX_N + nearest[2 * MAX_N + x]] <= threshold) 2 else 0;
}

fn refineFurther(u: usize, v: usize, iu: usize, nearest: *const [32]usize,
                 bunch: *const [64]bool) bool {
    if (iu < 2) return false;
    return bunch[v * MAX_N + nearest[u]] or bunch[u * MAX_N + nearest[MAX_N + v]] or
        bunch[v * MAX_N + nearest[iu * MAX_N + u]] or bunch[u * MAX_N + nearest[(iu + 1) * MAX_N + v]];
}

export fn wulff_nilsen_distance_refinement(input_opt: ?[*]const i64, length: usize) i64 {
    const input = input_opt orelse return -1;
    if (length < 8 or length > MAX_INPUT) return -1;
    const n_raw = input[0]; const m_raw = input[1];
    if (n_raw < 2 or n_raw > 8 or m_raw < 0 or m_raw > 28) return -1;
    const n: usize = @intCast(n_raw); const m: usize = @intCast(m_raw);
    if (length != 8 + 3 * m) return -1;
    const full = (@as(i64, 1) << @intCast(n)) - 1;
    var masks = [_]i64{0} ** 3;
    for (0..3) |i| { masks[i] = input[2 + i]; if (masks[i] <= 0 or (masks[i] & ~full) != 0) return -1; }
    if ((masks[1] & ~masks[0]) != 0 or (masks[2] & ~masks[1]) != 0) return -1;

    var distance = [_]i64{0} ** 64;
    for (0..n) |u| for (0..n) |v| { distance[u * MAX_N + v] = if (u == v) 0 else INF; };
    var previous_u: i64 = -1; var previous_v: i64 = -1;
    for (0..m) |e| {
        const at = 5 + 3 * e;
        const u = input[at]; const v = input[at + 1]; const weight = input[at + 2];
        if (u < 0 or u >= n_raw or v <= u or v >= n_raw or weight < SCALE or weight > 100 * SCALE or @rem(weight, SCALE) != 0) return -1;
        if (u < previous_u or (u == previous_u and v <= previous_v)) return -1;
        previous_u = u; previous_v = v;
        const ui: usize = @intCast(u); const vi: usize = @intCast(v);
        distance[ui * MAX_N + vi] = weight; distance[vi * MAX_N + ui] = weight;
    }
    const q = 5 + 3 * m;
    const source_raw = input[q]; const target_raw = input[q + 1]; const estimate = input[q + 2];
    if (source_raw < 0 or source_raw >= n_raw or target_raw < 0 or target_raw >= n_raw or source_raw == target_raw or estimate <= 0 or @rem(estimate, SCALE) != 0) return -1;
    const source: usize = @intCast(source_raw); const target: usize = @intCast(target_raw);

    for (0..n) |mid| for (0..n) |u| {
        if (distance[u * MAX_N + mid] == INF) continue;
        for (0..n) |v| { const candidate = distance[u * MAX_N + mid] + distance[mid * MAX_N + v]; if (candidate < distance[u * MAX_N + v]) distance[u * MAX_N + v] = candidate; }
    };
    for (0..n) |u| for (0..n) |v| { if (distance[u * MAX_N + v] == INF) return -1; };
    if (estimate < distance[source * MAX_N + target] or estimate > 768 * distance[source * MAX_N + target]) return -1;

    var nearest = [_]usize{0} ** 32;
    for (0..n) |x| {
        nearest[x] = x;
        for (1..4) |level| {
            var chosen: usize = MAX_N;
            for (0..n) |y| if (@as(u64, @bitCast(masks[level - 1])) >> @intCast(y) & 1 != 0) {
                if (chosen == MAX_N or distance[x * MAX_N + y] < distance[x * MAX_N + chosen] or (distance[x * MAX_N + y] == distance[x * MAX_N + chosen] and y < chosen)) chosen = y;
            };
            nearest[level * MAX_N + x] = chosen;
        }
    }
    const layers = [_]i64{full, masks[0], masks[1], masks[2], 0};
    var bunch = [_]bool{false} ** 64;
    for (0..n) |center| for (0..4) |level| {
        var boundary = INF;
        for (0..n) |y| if (@as(u64, @bitCast(layers[level + 1])) >> @intCast(y) & 1 != 0) { boundary = @min(boundary, distance[center * MAX_N + y]); };
        for (0..n) |y| {
            const in_current = (@as(u64, @bitCast(layers[level])) >> @intCast(y) & 1) != 0;
            const in_next = (@as(u64, @bitCast(layers[level + 1])) >> @intCast(y) & 1) != 0;
            if (in_current and !in_next and distance[center * MAX_N + y] < boundary) bunch[center * MAX_N + y] = true;
        }
    };

    var value = estimate;
    var iu = evenIndex(source, value, &nearest, &distance);
    if (!refineFurther(source, target, iu, &nearest, &bunch)) return value;
    var iteration: usize = 0;
    while (refineFurther(source, target, iu, &nearest, &bunch) and iteration <= 15) : (iteration += 1) {
        value = 2 * value / 3;
        iu = evenIndex(source, value, &nearest, &distance);
    }
    const upper = evenIndex(source, 3 * value / 2, &nearest, &distance);
    if (upper < 2) return -1;
    var pivot = nearest[source];
    if (bunch[target * MAX_N + pivot]) return distance[source * MAX_N + pivot] + distance[target * MAX_N + pivot];
    pivot = nearest[MAX_N + target];
    if (bunch[source * MAX_N + pivot]) return distance[source * MAX_N + pivot] + distance[target * MAX_N + pivot];
    pivot = nearest[upper * MAX_N + source];
    if (bunch[target * MAX_N + pivot]) return distance[source * MAX_N + pivot] + distance[target * MAX_N + pivot];
    pivot = nearest[(upper + 1) * MAX_N + target];
    return distance[source * MAX_N + pivot] + distance[target * MAX_N + pivot];
}
