export fn maximum_sum_bst(input: ?[*]const i64, length: usize) i64 {
    const max_slots = 31;
    const empty_min: i64 = 1_000_001;
    if (length < 1 or length > max_slots + 1 or input == null) return -1;
    const values = input.?;
    if (values[0] < 0 or values[0] > max_slots or length != @as(usize, @intCast(values[0])) + 1) return -1;
    const count: usize = @intCast(values[0]);
    for (0..count) |i| {
        if (values[i + 1] < -1 or values[i + 1] > 1_000_000) return -1;
        if (values[i + 1] != -1 and i > 0 and values[(i - 1) / 2 + 1] == -1) return -1;
    }
    if (count == 0) return 0;
    var valid: [max_slots]bool = @splat(false);
    var subtree_min: [max_slots]i64 = @splat(0);
    var subtree_max: [max_slots]i64 = @splat(0);
    var subtree_sum: [max_slots]i64 = @splat(0);
    var best: [max_slots]i64 = @splat(0);
    var remaining = count;
    while (remaining > 0) {
        remaining -= 1;
        const i = remaining;
        if (values[i + 1] == -1) { valid[i] = true; subtree_min[i] = empty_min; subtree_max[i] = -1; continue; }
        const left = 2 * i + 1; const right = left + 1;
        const lv = left >= count or valid[left]; const rv = right >= count or valid[right];
        const lmax: i64 = if (left < count) subtree_max[left] else -1;
        const rmin: i64 = if (right < count) subtree_min[right] else empty_min;
        const lmin: i64 = if (left < count) subtree_min[left] else empty_min;
        const rmax: i64 = if (right < count) subtree_max[right] else -1;
        const lsum: i64 = if (left < count) subtree_sum[left] else 0;
        const rsum: i64 = if (right < count) subtree_sum[right] else 0;
        const lb: i64 = if (left < count) best[left] else 0;
        const rb: i64 = if (right < count) best[right] else 0;
        const value = values[i + 1];
        if (lv and rv and lmax < value and value < rmin) {
            valid[i] = true; subtree_min[i] = @min(lmin, value); subtree_max[i] = @max(rmax, value);
            subtree_sum[i] = lsum + rsum + value; best[i] = @max(subtree_sum[i], lb, rb);
        } else { best[i] = @max(lb, rb); }
    }
    return best[0];
}
