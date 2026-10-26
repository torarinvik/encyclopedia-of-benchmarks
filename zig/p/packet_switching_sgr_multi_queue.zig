const MAX_QUEUES: usize = 4;
const MAX_SLOTS: usize = 8;
const MAX_INPUT: usize = 36;
const MAX_OUTPUT_BYTES: usize = 64;

fn store_i64_le(output: [*]u8, offset: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |byte| output[offset + byte] = @truncate(bits >> @intCast(8 * byte));
}

export fn packet_switching_sgr_multi_queue(input_opt: ?[*]const i64, length: usize,
    output_opt: ?[*]u8, capacity: usize) i64 {
    if (input_opt == null or length < 3 or length > MAX_INPUT) return -1;
    const input = input_opt.?;
    if (input[0] < 2 or input[0] > @as(i64, MAX_QUEUES) or input[1] < 1 or input[1] > 4 or
        input[2] < 1 or input[2] > @as(i64, MAX_SLOTS)) return -1;
    const queues: usize = @intCast(input[0]);
    const buffer = input[1];
    const slots: usize = @intCast(input[2]);
    if (length != 3 + queues * slots) return -1;
    var loads: [MAX_QUEUES]i64 = @splat(0);
    var peaks: [MAX_QUEUES]i64 = @splat(0);
    var schedule: [MAX_SLOTS]i64 = @splat(-1);
    for (0..slots) |slot| {
        for (0..queues) |queue| {
            const arrivals = input[3 + slot * queues + queue];
            if (arrivals < 0 or arrivals > buffer) return -1;
            loads[queue] += arrivals;
            if (loads[queue] > buffer) loads[queue] = buffer;
            if (loads[queue] > peaks[queue]) peaks[queue] = loads[queue];
        }
        var has_large = false;
        var has_nonempty = false;
        var has_underfull_peak = false;
        for (0..queues) |queue| {
            if (loads[queue] > 0) {
                has_nonempty = true;
                if (loads[queue] > @divTrunc(buffer, 2)) has_large = true;
                if (peaks[queue] < buffer) has_underfull_peak = true;
            }
        }
        if (!has_nonempty) {
            @memset(&peaks, 0);
            continue;
        }
        const use_history = !has_large and has_underfull_peak;
        var selected = queues;
        for (0..queues) |queue| {
            if (loads[queue] == 0 or (use_history and peaks[queue] >= buffer)) continue;
            if (selected == queues or loads[queue] > loads[selected]) selected = queue;
        }
        schedule[slot] = @intCast(selected);
        loads[selected] -= 1;
        var any_left = false;
        for (0..queues) |queue| {
            if (loads[queue] > 0) any_left = true;
        }
        if (!any_left) @memset(&peaks, 0);
    }
    const output_bytes = 8 * slots;
    if (output_opt == null or capacity < output_bytes) return -2;
    const output = output_opt.?;
    var staged: [MAX_OUTPUT_BYTES]u8 = @splat(0);
    for (0..slots) |slot| store_i64_le(&staged, 8 * slot, schedule[slot]);
    for (0..output_bytes) |byte| output[byte] = staged[byte];
    return @intCast(output_bytes);
}
