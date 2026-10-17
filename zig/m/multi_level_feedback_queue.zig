const MAX_QUEUES: usize = 4;
const MAX_PROCESSES: usize = 8;
const MAX_INPUT_WORDS: usize = 13;
const MAX_OUTPUT_WORDS: usize = 1 + 4 * MAX_PROCESSES;

const Process = struct { id: i32, remaining: i32, waiting: i32, turnaround: i32, stop_time: i32 };

fn putI32Le(output: [*]u8, offset: usize, value: i32) void {
    const bits: u32 = @bitCast(value);
    for (0..4) |byte| output[offset + byte] = @truncate(bits >> @intCast(8 * byte));
}

export fn multi_level_feedback_queue(input_opt: ?[*]const i32, length: usize,
    output_opt: ?[*]u8, capacity: usize) i64 {
    if (input_opt == null or length < 2 or length > MAX_INPUT_WORDS) return -1;
    const input = input_opt.?;
    const queue_count = input[0];
    const process_count = input[1];
    if (queue_count < 1 or queue_count > @as(i32, @intCast(MAX_QUEUES)) or
        process_count < 0 or process_count > @as(i32, @intCast(MAX_PROCESSES)) or
        length != 2 + @as(usize, @intCast(queue_count - 1)) + @as(usize, @intCast(process_count))) return -1;

    var slices: [MAX_QUEUES - 1]i32 = [_]i32{0} ** (MAX_QUEUES - 1);
    var pos: usize = 2;
    for (0..@intCast(queue_count - 1)) |i| {
        if (input[pos] < 1 or input[pos] > 16) return -1;
        slices[i] = input[pos];
        pos += 1;
    }
    var ready: [MAX_PROCESSES]Process = undefined;
    var ready_count: usize = @intCast(process_count);
    for (0..ready_count) |i| {
        const burst = input[pos];
        pos += 1;
        if (burst < 1 or burst > 16) return -1;
        ready[i] = .{ .id = @intCast(i), .remaining = burst, .waiting = 0, .turnaround = 0, .stop_time = 0 };
    }

    var finished: [MAX_PROCESSES]Process = undefined;
    var finished_count: usize = 0;
    var current_time: i32 = 0;
    for (0..@intCast(queue_count - 1)) |level| {
        var next_ready: [MAX_PROCESSES]Process = undefined;
        var next_count: usize = 0;
        const time_slice = slices[level];
        for (0..ready_count) |i| {
            var process = ready[i];
            process.waiting += current_time - process.stop_time;
            if (process.remaining > time_slice) {
                current_time += time_slice;
                process.remaining -= time_slice;
                process.stop_time = current_time;
                next_ready[next_count] = process;
                next_count += 1;
            } else {
                current_time += process.remaining;
                process.remaining = 0;
                process.stop_time = current_time;
                process.turnaround = current_time;
                finished[finished_count] = process;
                finished_count += 1;
            }
        }
        ready_count = next_count;
        for (0..next_count) |i| ready[i] = next_ready[i];
    }
    for (0..ready_count) |i| {
        var process = ready[i];
        process.waiting += current_time - process.stop_time;
        current_time += process.remaining;
        process.remaining = 0;
        process.stop_time = current_time;
        process.turnaround = current_time;
        finished[finished_count] = process;
        finished_count += 1;
    }

    if (finished_count != @as(usize, @intCast(process_count))) return -1;
    var words: [MAX_OUTPUT_WORDS]i32 = undefined;
    var word_count: usize = 1;
    words[0] = process_count;
    for (0..finished_count) |i| {
        words[word_count] = finished[i].id;
        words[word_count + 1] = finished[i].waiting;
        words[word_count + 2] = finished[i].turnaround;
        words[word_count + 3] = finished[i].stop_time;
        word_count += 4;
    }
    const bytes = word_count * 4;
    if (output_opt == null or capacity < bytes) return -2;
    const output = output_opt.?;
    var buffer: [MAX_OUTPUT_WORDS * 4]u8 = undefined;
    for (0..word_count) |i| putI32Le(&buffer, i * 4, words[i]);
    for (0..bytes) |i| output[i] = buffer[i];
    return @intCast(bytes);
}
