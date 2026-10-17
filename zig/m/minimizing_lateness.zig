const MAX_JOBS: usize = 64;
const MAX_OUTPUT: usize = 4 + 12 * MAX_JOBS;
const I32_MAX: i64 = 2_147_483_647;

const Job = struct {
    processing: i32,
    deadline: i32,
    original_index: i32,
    start_time: i32,
    lateness: i32,
};

fn writeI32(output: *[MAX_OUTPUT]u8, offset: usize, value: i32) void {
    const bits: u32 = @bitCast(value);
    for (0..4) |byte| output[offset + byte] = @truncate(bits >> @intCast(8 * byte));
}

export fn minimizing_lateness(input: [*c]const i64, length: usize,
    output: [*c]u8, capacity: usize) i64 {
    if (input == null or length < 1 or length > 1 + 2 * MAX_JOBS) return -1;
    const count_value = input[0];
    if (count_value < 0 or count_value > @as(i64, @intCast(MAX_JOBS)) or length != 1 + 2 * @as(usize, @intCast(count_value))) return -1;
    const count: usize = @intCast(count_value);
    var jobs: [MAX_JOBS]Job = undefined;
    var total_processing: i64 = 0;
    for (0..count) |i| {
        const processing = input[1 + 2 * i];
        const deadline = input[2 + 2 * i];
        if (processing < 0 or processing > I32_MAX or deadline < 0 or deadline > I32_MAX) return -1;
        total_processing += processing;
        if (total_processing > I32_MAX) return -1;
        jobs[i] = .{ .processing = @intCast(processing), .deadline = @intCast(deadline),
            .original_index = @intCast(i), .start_time = 0, .lateness = 0 };
    }
    var i: usize = 1;
    while (i < count) : (i += 1) {
        const item = jobs[i];
        var position = i;
        while (position > 0 and jobs[position - 1].deadline > item.deadline) : (position -= 1) {
            jobs[position] = jobs[position - 1];
        }
        jobs[position] = item;
    }
    var start_time: i64 = 0;
    for (0..count) |job_index| {
        jobs[job_index].start_time = @intCast(start_time);
        const finish_time = start_time + jobs[job_index].processing;
        const lateness = finish_time - jobs[job_index].deadline;
        jobs[job_index].lateness = @intCast(if (lateness > 0) lateness else 0);
        start_time = finish_time;
    }
    const needed = 4 + 12 * count;
    if (output == null or capacity < needed) return -2;
    var payload: [MAX_OUTPUT]u8 = undefined;
    writeI32(&payload, 0, @intCast(count));
    for (0..count) |job_index| {
        const offset = 4 + 12 * job_index;
        writeI32(&payload, offset, jobs[job_index].original_index);
        writeI32(&payload, offset + 4, jobs[job_index].start_time);
        writeI32(&payload, offset + 8, jobs[job_index].lateness);
    }
    for (0..needed) |byte| output[byte] = payload[byte];
    return @intCast(needed);
}
