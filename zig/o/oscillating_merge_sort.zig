const MAX_VALUES: usize = 1024;
const MAX_PARTS: usize = 2;
const INITIAL_RUN_SIZE: usize = 16;

fn buildRun(values: [*]const i64, value_count: usize, run_size: usize,
    merge_inputs: usize, first_run: usize, run_count: usize,
    ascending: bool, output: [*]i64) usize {
    if (run_count == 1) {
        const start = first_run * run_size;
        const length = @min(run_size, value_count - start);
        for (0..length) |i| output[i] = values[start + i];
        for (1..length) |i| {
            const value = output[i];
            var position = i;
            while (position > 0) {
                const previous = output[position - 1];
                if ((ascending and value >= previous) or (!ascending and value <= previous)) break;
                output[position] = previous;
                position -= 1;
            }
            output[position] = value;
        }
        return length;
    }

    var children: [MAX_PARTS][MAX_VALUES]i64 = undefined;
    var lengths: [MAX_PARTS]usize = .{0} ** MAX_PARTS;
    var positions: [MAX_PARTS]usize = .{0} ** MAX_PARTS;
    const quotient = run_count / merge_inputs;
    const remainder = run_count % merge_inputs;
    var next_run = first_run;
    var total: usize = 0;
    for (0..merge_inputs) |lane| {
        const child_count = quotient + @intFromBool(lane < remainder);
        if (child_count == 0) continue;
        lengths[lane] = buildRun(values, value_count, run_size, merge_inputs,
            next_run, child_count, !ascending, &children[lane][0]);
        next_run += child_count;
        total += lengths[lane];
    }
    for (0..total) |out| {
        var best_lane = MAX_PARTS;
        var best_value: i64 = 0;
        for (0..merge_inputs) |lane| {
            if (positions[lane] >= lengths[lane]) continue;
            const candidate = children[lane][lengths[lane] - 1 - positions[lane]];
            if (best_lane == MAX_PARTS or (ascending and candidate < best_value)
                or (!ascending and candidate > best_value)) {
                best_lane = lane;
                best_value = candidate;
            }
        }
        output[out] = best_value;
        positions[best_lane] += 1;
    }
    return total;
}

export fn oscillating_merge_sort(values: [*]i64, length: usize) void {
    if (length == 0 or length > MAX_VALUES) return;
    var sorted: [MAX_VALUES]i64 = undefined;
    const run_count = (length + INITIAL_RUN_SIZE - 1) / INITIAL_RUN_SIZE;
    _ = buildRun(values, length, INITIAL_RUN_SIZE, MAX_PARTS, 0,
        run_count, true, &sorted[0]);
    for (0..length) |i| values[i] = sorted[i];
}
