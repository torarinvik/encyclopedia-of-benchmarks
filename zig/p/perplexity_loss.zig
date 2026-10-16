const MAX_INPUT_LENGTH: usize = 3 + 8 * 16 * 17;
const INVALID_RESULT: f64 = -1.0e300;

export fn perplexity_loss(values: [*]const i64, length: usize) f64 {
    if (length < 3 or length > MAX_INPUT_LENGTH) return INVALID_RESULT;
    const batch_value, const time_value, const vocab_value = .{ values[0], values[1], values[2] };
    if (batch_value < 1 or batch_value > 8 or time_value < 1 or time_value > 16 or vocab_value < 2 or vocab_value > 16) return INVALID_RESULT;
    const batch: usize = @intCast(batch_value);
    const time: usize = @intCast(time_value);
    const vocab: usize = @intCast(vocab_value);
    const tokens = batch * time;
    const probability_base = 3 + tokens;
    if (length != probability_base + tokens * vocab) return INVALID_RESULT;
    for (0..tokens) |row| {
        const label = values[3 + row];
        if (label < 0 or label >= vocab_value) return INVALID_RESULT;
        var row_sum: i64 = 0;
        for (0..vocab) |c| {
            const p = values[probability_base + row * vocab + c];
            if (p < 0 or p > 1_000_000) return INVALID_RESULT;
            row_sum += p;
        }
        if (row_sum != 1_000_000) return INVALID_RESULT;
    }
    var batch_total: f64 = 0.0;
    for (0..batch) |sentence| {
        var log_total: f64 = 0.0;
        for (0..time) |step| {
            const row = sentence * time + step;
            const label: usize = @intCast(values[3 + row]);
            var p = @as(f64, @floatFromInt(values[probability_base + row * vocab + label])) / 1_000_000.0;
            if (p < 1e-7) p = 1e-7;
            if (p > 1.0) p = 1.0;
            log_total += @log(p);
        }
        batch_total += @exp(-(log_total / @as(f64, @floatFromInt(time))));
    }
    return batch_total / @as(f64, @floatFromInt(batch));
}
