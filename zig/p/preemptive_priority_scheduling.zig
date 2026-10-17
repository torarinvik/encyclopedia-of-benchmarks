const MAX_PROCESSES: usize = 8;
const MAX_SCHEDULE_TICKS: usize = 80;

fn putI32Le(output: [*c]u8, offset: usize, value: i32) void {
    const bits: u32 = @bitCast(value);
    for (0..4) |byte| output[offset + byte] = @truncate(bits >> @intCast(8 * byte));
}

export fn preemptive_priority_scheduling(input: [*c]const i32, length: usize,
    output: [*c]u8, capacity: usize) i64 {
    if (input == null or length < 1 or length > 33) return -1;
    const process_count = input[0];
    if (process_count < 0 or process_count > MAX_PROCESSES or
        length != 1 + 4 * @as(usize, @intCast(process_count))) return -1;

    var ids: [MAX_PROCESSES]i32 = @splat(0);
    var arrivals: [MAX_PROCESSES]i32 = @splat(0);
    var remaining: [MAX_PROCESSES]i32 = @splat(0);
    var priorities: [MAX_PROCESSES]i32 = @splat(0);
    var seen_ids: [MAX_PROCESSES]bool = @splat(false);
    for (0..@intCast(process_count)) |i| {
        const offset = 1 + 4 * i;
        const id = input[offset];
        const arrival = input[offset + 1];
        const burst = input[offset + 2];
        const priority = input[offset + 3];
        if (id < 0 or id >= MAX_PROCESSES or seen_ids[@intCast(id)] or
            arrival < 0 or arrival > 16 or burst < 1 or burst > 8) return -1;
        for (0..i) |previous| {
            if (priorities[previous] == priority and arrivals[previous] == arrival) return -1;
        }
        seen_ids[@intCast(id)] = true;
        ids[i] = id;
        arrivals[i] = arrival;
        remaining[i] = burst;
        priorities[i] = priority;
    }

    var schedule: [MAX_SCHEDULE_TICKS]i32 = @splat(0);
    var tick_count: usize = 0;
    var completed: usize = 0;
    while (completed < @as(usize, @intCast(process_count))) {
        var best: usize = @intCast(process_count);
        for (0..@as(usize, @intCast(process_count))) |i| {
            if (remaining[i] <= 0 or arrivals[i] > @as(i32, @intCast(tick_count))) continue;
            if (best == @as(usize, @intCast(process_count)) or priorities[i] > priorities[best] or
                (priorities[i] == priorities[best] and arrivals[i] < arrivals[best])) best = i;
        }
        if (best == @as(usize, @intCast(process_count))) {
            schedule[tick_count] = -1;
        } else {
            schedule[tick_count] = ids[best];
            remaining[best] -= 1;
            if (remaining[best] == 0) completed += 1;
        }
        tick_count += 1;
    }

    const bytes = (1 + tick_count) * 4;
    if (output == null or capacity < bytes) return -2;
    putI32Le(output, 0, @intCast(tick_count));
    for (0..tick_count) |i| putI32Le(output, 4 * (i + 1), schedule[i]);
    return @intCast(bytes);
}
