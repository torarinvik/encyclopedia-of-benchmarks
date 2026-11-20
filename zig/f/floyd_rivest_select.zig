const MAX_VALUES: usize = 64;
const MAX_INPUT_LENGTH: usize = 67;
const SAMPLE_THRESHOLD: usize = 24;

fn selectRange(values: *[MAX_VALUES]i64, left_input: usize,
    right_input: usize, target: usize) void {
    var left = left_input;
    var right = right_input;
    while (true) {
        if (right - left > SAMPLE_THRESHOLD) {
            const active_count = right - left + 1;
            const relative_rank = target - left + 1;
            const active_count_f: f64 = @floatFromInt(active_count);
            const relative_rank_f: f64 = @floatFromInt(relative_rank);
            const z = @sqrt(@log(active_count_f));
            const sample_size = 0.5 * @exp(2.0 * z / 3.0);
            const direction: f64 = if (2 * relative_rank < active_count) -1.0 else if (2 * relative_rank > active_count) 1.0 else 0.0;
            const spread = 0.5 * @sqrt(z * sample_size *
                (active_count_f - sample_size) / active_count_f) * direction;
            const lower_estimate = @as(f64, @floatFromInt(target)) -
                relative_rank_f * sample_size / active_count_f + spread;
            const upper_estimate = @as(f64, @floatFromInt(target)) +
                (active_count_f - relative_rank_f) * sample_size / active_count_f + spread;
            var sample_left: i64 = @intFromFloat(@floor(lower_estimate));
            const left_i64: i64 = @intCast(left);
            const target_i64: i64 = @intCast(target);
            if (sample_left < left_i64) sample_left = left_i64;
            if (sample_left > target_i64) sample_left = target_i64;
            var sample_right: i64 = @intFromFloat(@ceil(upper_estimate));
            const right_i64: i64 = @intCast(right);
            if (sample_right < target_i64) sample_right = target_i64;
            if (sample_right > right_i64) sample_right = right_i64;
            selectRange(values, @intCast(sample_left), @intCast(sample_right), target);
        }

        const pivot = values[target];
        var less = left;
        var scan = left;
        var greater = right;
        while (scan <= greater) {
            if (values[scan] < pivot) {
                const temporary = values[less];
                values[less] = values[scan];
                values[scan] = temporary;
                less += 1;
                scan += 1;
            } else if (values[scan] > pivot) {
                const temporary = values[greater];
                values[greater] = values[scan];
                values[scan] = temporary;
                greater -= 1;
            } else {
                scan += 1;
            }
        }
        if (target < less) {
            right = less - 1;
        } else if (target > greater) {
            left = greater + 1;
        } else {
            return;
        }
    }
}

export fn floyd_rivest_select(input_opt: ?[*]const i64, length: usize) i64 {
    if (input_opt == null or length < 3 or length > MAX_INPUT_LENGTH) return -1;
    const input = input_opt.?;
    const raw_count = input[0];
    const raw_rank = input[1];
    if (raw_count < 1 or raw_count > @as(i64, @intCast(MAX_VALUES)) or raw_rank < 0 or raw_rank >= raw_count) return -1;
    const count: usize = @intCast(raw_count);
    if (length != count + 2) return -1;

    var values: [MAX_VALUES]i64 = @splat(0);
    for (0..count) |index| {
        const value = input[index + 2];
        if (value < 0 or value > 2147483647) return -1;
        for (0..index) |previous| {
            if (values[previous] == value) return -1;
        }
        values[index] = value;
    }

    const target: usize = @intCast(raw_rank);
    selectRange(&values, 0, count - 1, target);
    return values[target];
}
