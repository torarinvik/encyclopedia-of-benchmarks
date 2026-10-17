fn put_i64_le(output: [*]u8, offset: usize, value: i64) void {
    const bits = @as(u64, @bitCast(value));
    for (0..8) |byte| output[offset + byte] = @truncate(bits >> @intCast(8 * byte));
}

export fn mlfqscheduler(input: [*c]const i64, length: usize, output: [*c]u8, output_capacity: usize) i64 {
    if (input == null or length < 2 or length > 55) return -1;
    const levels_value = input[0];
    const process_count_value = input[1];
    if (levels_value < 1 or levels_value > 4 or process_count_value < 0 or process_count_value > 16) return -1;
    const levels: usize = @intCast(levels_value);
    const process_count: usize = @intCast(process_count_value);
    if (length != 2 + levels + 3 * process_count) return -1;
    var quanta: [4]i64 = @splat(0);
    var pids: [16]i64 = @splat(0);
    var remaining: [16]i64 = @splat(0);
    for (0..levels) |level| {
        quanta[level] = input[2 + level];
        if (quanta[level] < 1 or quanta[level] > 32) return -1;
    }
    const process_offset = 2 + levels;
    for (0..process_count) |i| {
        const pid = input[process_offset + 3 * i];
        const burst = input[process_offset + 3 * i + 1];
        const arrival = input[process_offset + 3 * i + 2];
        if (pid < -2147483648 or pid > 2147483647 or burst < 0 or burst > 1000 or arrival < 0 or arrival > 1000000) return -1;
        pids[i] = pid;
        remaining[i] = burst;
    }

    var queues: [64]usize = @splat(0);
    var queue_counts: [4]usize = @splat(0);
    for (0..process_count) |i| queues[i] = i;
    queue_counts[0] = process_count;
    var completion_pids: [16]i64 = @splat(0);
    var completion_times: [16]i64 = @splat(0);
    var completions: usize = 0;
    var current_time: i64 = 0;
    while (true) {
        var active: usize = 0;
        for (0..levels) |level| active += queue_counts[level];
        if (active == 0) break;
        for (0..levels) |level| {
            const base = level * 16;
            const queued = queue_counts[level];
            if (queued == 0) continue;
            const process = queues[base];
            for (1..queued) |j| queues[base + j - 1] = queues[base + j];
            queue_counts[level] -= 1;
            const slice = @min(quanta[level], remaining[process]);
            current_time += slice;
            remaining[process] -= slice;
            if (remaining[process] == 0) {
                completion_pids[completions] = pids[process];
                completion_times[completions] = current_time;
                completions += 1;
            } else {
                const destination = if (level + 1 < levels) level + 1 else level;
                queues[destination * 16 + queue_counts[destination]] = process;
                queue_counts[destination] += 1;
            }
        }
    }

    const elements = 2 + 2 * completions;
    const required = elements * 8;
    if (output == null or output_capacity < required) return -2;
    const out: [*]u8 = @ptrCast(output);
    put_i64_le(out, 0, current_time);
    put_i64_le(out, 8, @intCast(completions));
    for (0..completions) |i| {
        put_i64_le(out, 16 + 16 * i, completion_pids[i]);
        put_i64_le(out, 24 + 16 * i, completion_times[i]);
    }
    return @intCast(elements);
}
