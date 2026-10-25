const MAX_CHILDREN: usize = 8;
const MAX_INPUT_LENGTH: usize = 1 + 8 * MAX_CHILDREN + 8;

fn validBox(values: [*]const i64, at: usize) bool {
    for (0..4) |d| {
        if (values[at + d] < -8 or values[at + d] > 8 or values[at + 4 + d] < -8 or values[at + 4 + d] > 8 or values[at + d] >= values[at + 4 + d]) return false;
    }
    return true;
}

fn volumeAt(values: [*]const i64, at: usize) i64 {
    var result: i64 = 1;
    for (0..4) |d| result *= values[at + 4 + d] - values[at + d];
    return result;
}

fn penaltyAt(values: [*]const i64, child: usize, incoming: usize) i64 {
    var joined_volume: i64 = 1;
    for (0..4) |d| {
        const lo = @min(values[child + d], values[incoming + d]);
        const hi = @max(values[child + 4 + d], values[incoming + 4 + d]);
        joined_volume *= hi - lo;
    }
    return joined_volume - volumeAt(values, child);
}

export fn versabench_dbms_choose_entry(raw: [*c]const i64, length: usize) i64 {
    if (raw == null or length < 1 or length > MAX_INPUT_LENGTH + 1) return -1;
    const values: [*]const i64 = raw;
    const raw_count = values[0];
    if (raw_count < 1 or raw_count > MAX_CHILDREN) return -1;
    const count: usize = @intCast(raw_count);
    if (length != 1 + 8 * count + 8) return -1;
    const incoming = 1 + 8 * count;
    for (0..count) |i| if (!validBox(values, 1 + 8 * i)) return -1;
    if (!validBox(values, incoming)) return -1;
    var best: usize = 0;
    var best_penalty = penaltyAt(values, 1, incoming);
    for (1..count) |i| {
        const candidate = penaltyAt(values, 1 + 8 * i, incoming);
        if (candidate < best_penalty) { best = i; best_penalty = candidate; }
    }
    return @intCast(best);
}
