const MAX_INPUT_LENGTH: usize = 130;
const MAX_PROCESSES: usize = 64;
const MAX_OUTPUT_BYTES: usize = 256;

fn writeI32Le(output: []u8, offset: usize, value: i32) void {
    const bits: u32 = @bitCast(value);
    for (0..4) |byte| output[offset + byte] = @truncate(bits >> @intCast(byte * 8));
}

fn execute(input: []const i32, order: *[MAX_PROCESSES]i32) ?usize {
    if (input.len < 1 or input.len > MAX_INPUT_LENGTH) return null;
    const process_count_value = input[0];
    if (process_count_value < 0 or process_count_value > @as(i32, MAX_PROCESSES)
        or input.len != 1 + 2 * @as(usize, @intCast(process_count_value))) return null;
    const process_count: usize = @intCast(process_count_value);

    var arrivals: [MAX_PROCESSES]i32 = [_]i32{0} ** MAX_PROCESSES;
    var bursts: [MAX_PROCESSES]i32 = [_]i32{0} ** MAX_PROCESSES;
    var completed: [MAX_PROCESSES]bool = [_]bool{false} ** MAX_PROCESSES;
    var cursor: usize = 1;
    for (0..process_count) |index| {
        const arrival = input[cursor];
        const burst = input[cursor + 1];
        cursor += 2;
        if (arrival < 0 or arrival > 255 or burst < 1 or burst > 255) return null;
        arrivals[index] = arrival;
        bursts[index] = burst;
    }

    var current_time: i32 = 0;
    var scheduled: usize = 0;
    while (scheduled < process_count) {
        var best: usize = process_count;
        for (0..process_count) |index| {
            if (completed[index] or arrivals[index] > current_time) continue;
            if (best == process_count or bursts[index] < bursts[best]
                or (bursts[index] == bursts[best]
                    and (arrivals[index] < arrivals[best]
                        or (arrivals[index] == arrivals[best] and index < best)))) {
                best = index;
            }
        }
        if (best == process_count) {
            current_time += 1;
        } else {
            order[scheduled] = @intCast(best);
            scheduled += 1;
            completed[best] = true;
            current_time += bursts[best];
        }
    }
    return process_count;
}

export fn sjfscheduling(input_opt: ?[*]const i32, length: usize,
    output_opt: ?[*]u8, capacity: usize) i64 {
    if (input_opt == null or length < 1 or length > MAX_INPUT_LENGTH) return -1;
    const input = input_opt.?[0..length];
    var order: [MAX_PROCESSES]i32 = [_]i32{0} ** MAX_PROCESSES;
    const process_count = execute(input, &order) orelse return -1;
    const output_bytes = process_count * 4;
    if (output_opt == null or capacity < output_bytes or output_bytes > MAX_OUTPUT_BYTES) return -2;
    const output = output_opt.?[0..output_bytes];
    for (0..process_count) |index| writeI32Le(output, index * 4, order[index]);
    return @intCast(output_bytes);
}
