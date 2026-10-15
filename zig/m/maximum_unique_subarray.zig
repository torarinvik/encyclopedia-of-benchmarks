export fn maximum_unique_subarray(values: [*]const i64, length: usize) i64 {
    if (length > 256) return -1;
    var keys: [512]i64 = @splat(0);
    var last_seen: [512]usize = @splat(0);
    var occupied: [512]bool = @splat(false);
    var left: usize = 0;
    var window_sum: i64 = 0;
    var best: i64 = 0;
    for (0..length) |index| {
        const value = values[index];
        if (value < 1 or value > 10_000) return -1;
        var slot: usize = @intCast(@mod(value, 512));
        while (occupied[slot] and keys[slot] != value) : (slot = (slot + 1) % 512) {}
        const previous = last_seen[slot];
        while (left < previous) : (left += 1) {
            window_sum -= values[left];
        }
        window_sum += value;
        keys[slot] = value;
        last_seen[slot] = index + 1;
        occupied[slot] = true;
        best = @max(best, window_sum);
    }
    return best;
}
