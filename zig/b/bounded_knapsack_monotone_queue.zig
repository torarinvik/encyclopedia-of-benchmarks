/// Bounded knapsack by residue-class sliding maxima.
export fn bounded_knapsack_monotone_queue(input_values: [*c]const i64, length: usize) i64 {
    if (input_values == null or length < 2 or length > 51) return -1;
    if (input_values[0] < 0 or input_values[0] > 64 or input_values[1] < 0 or input_values[1] > 16) return -1;
    const capacity: usize = @intCast(input_values[0]);
    const types: usize = @intCast(input_values[1]);
    if (length != 2 + 3 * types) return -1;
    for (0..types) |item| {
        const weight = input_values[2 + 3 * item];
        const value = input_values[3 + 3 * item];
        const count = input_values[4 + 3 * item];
        if (weight < 1 or weight > 16 or value < 0 or value > 100 or count < 0 or count > 16) return -1;
    }

    var dp: [65]i64 = @splat(0);
    var next: [65]i64 = @splat(0);
    var queue_score: [65]i64 = @splat(0);
    var queue_index: [65]usize = @splat(0);
    for (0..types) |item| {
        const weight: usize = @intCast(input_values[2 + 3 * item]);
        const value = input_values[3 + 3 * item];
        const count: usize = @intCast(input_values[4 + 3 * item]);
        var residue: usize = 0;
        while (residue < weight and residue <= capacity) : (residue += 1) {
            var head: usize = 0;
            var tail: usize = 0;
            const max_t = (capacity - residue) / weight;
            var t: usize = 0;
            while (t <= max_t) : (t += 1) {
                const current = residue + t * weight;
                const score = dp[current] - @as(i64, @intCast(t)) * value;
                while (tail > head and queue_score[tail - 1] <= score) tail -= 1;
                queue_index[tail] = t;
                queue_score[tail] = score;
                tail += 1;
                const first_allowed = if (t > count) t - count else 0;
                while (head < tail and queue_index[head] < first_allowed) head += 1;
                next[current] = @as(i64, @intCast(t)) * value + queue_score[head];
            }
        }
        for (0..capacity + 1) |c| dp[c] = next[c];
    }
    return dp[capacity];
}
