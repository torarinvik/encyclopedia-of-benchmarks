const MAX_TASKS: usize = 8;
const MAX_INPUT: usize = 17;
const MAX_OUTPUT_BYTES: usize = 80;

fn store_i64_le(output: [*]u8, offset: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |byte| output[offset + byte] = @truncate(bits >> @intCast(8 * byte));
}

export fn rate_monotonic_scheduling(input_opt: ?[*]const i64, length: usize,
    output_opt: ?[*]u8, capacity: usize) i64 {
    if (input_opt == null or length < 3 or length > MAX_INPUT) return -1;
    const input = input_opt.?;
    if (input[0] < 1 or input[0] > @as(i64, MAX_TASKS)) return -1;
    const count: usize = @intCast(input[0]);
    if (length != 1 + 2 * count) return -1;
    var execution: [MAX_TASKS]i64 = @splat(0);
    var period: [MAX_TASKS]i64 = @splat(0);
    var order: [MAX_TASKS]usize = @splat(0);
    var response: [MAX_TASKS]i64 = @splat(-1);
    for (0..count) |task| {
        execution[task] = input[1 + 2 * task];
        period[task] = input[2 + 2 * task];
        if (execution[task] < 1 or execution[task] > 16 or period[task] < 1 or period[task] > 32) return -1;
        order[task] = task;
    }
    for (1..count) |index| {
        const key = order[index];
        var position = index;
        while (position > 0 and (period[order[position - 1]] > period[key] or
            (period[order[position - 1]] == period[key] and order[position - 1] > key))) {
            order[position] = order[position - 1];
            position -= 1;
        }
        order[position] = key;
    }

    var schedulable: i64 = 1;
    var failed_task: i64 = -1;
    for (0..count) |rank| {
        const target = order[rank];
        var remaining_target = execution[target];
        var active: [MAX_TASKS]i64 = @splat(0);
        var elapsed: i64 = 0;
        while (remaining_target > 0 and elapsed < period[target]) {
            for (0..rank) |higher_rank| {
                const higher = order[higher_rank];
                if (@mod(elapsed, period[higher]) == 0) active[higher] += execution[higher];
            }
            var selected: ?usize = null;
            for (0..rank) |higher_rank| {
                const higher = order[higher_rank];
                if (active[higher] > 0) { selected = higher; break; }
            }
            if (selected) |higher| active[higher] -= 1 else remaining_target -= 1;
            elapsed += 1;
        }
        if (remaining_target > 0) {
            schedulable = 0;
            failed_task = @intCast(target);
            break;
        }
        response[target] = elapsed;
    }

    const output_bytes = 8 * (count + 2);
    if (output_opt == null or capacity < output_bytes) return -2;
    const output = output_opt.?;
    var staged: [MAX_OUTPUT_BYTES]u8 = @splat(0);
    store_i64_le(&staged, 0, schedulable);
    store_i64_le(&staged, 8, failed_task);
    for (0..count) |task| store_i64_le(&staged, 8 * (task + 2), response[task]);
    for (0..output_bytes) |byte| output[byte] = staged[byte];
    return @intCast(output_bytes);
}
