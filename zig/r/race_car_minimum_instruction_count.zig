const MAX_TARGET: i64 = 127;
const MAX_INPUT_LENGTH: usize = 2;

export fn race_car_minimum_instruction_count(
    input_opt: ?[*]const i64,
    length: usize,
) i64 {
    if (input_opt == null or length < 1 or length > MAX_INPUT_LENGTH) return -1;
    if (length != 1) return -1;
    const input = input_opt.?;
    const target_value = input[0];
    if (target_value < 0 or target_value > MAX_TARGET) return -1;
    const target: usize = @intCast(target_value);
    var distance: [128]i32 = @splat(0);

    for (1..(target + 1)) |position| {
        var run: usize = 0;
        var upper_power: usize = 1;
        while (upper_power <= position) {
            upper_power *= 2;
            run += 1;
        }
        const upper = upper_power - 1;
        if (position == upper) {
            distance[position] = @intCast(run);
            continue;
        }

        var best: i32 = @intCast(run + 1);
        best += distance[upper - position];
        const lower = upper_power / 2 - 1;
        var backward_run: usize = 0;
        var backward_power: usize = 1;
        while (backward_run + 1 < run) {
            const backward_distance = backward_power - 1;
            const remaining = position - (lower - backward_distance);
            const candidate: i32 = @intCast(run + backward_run + 1);
            const total = candidate + distance[remaining];
            if (total < best) best = total;
            backward_power *= 2;
            backward_run += 1;
        }
        distance[position] = best;
    }
    return distance[target];
}
