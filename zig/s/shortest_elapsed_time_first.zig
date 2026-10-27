const max_jobs: usize = 8;
const max_input: usize = 18;
const max_output: usize = 112;

export fn shortest_elapsed_time_first(input_opt: ?[*]const i64, length: usize,
    output_opt: ?[*]u8, capacity: usize) i64 {
    if (input_opt == null or length < 1 or length > max_input) return -1;
    const input = input_opt.?;
    const n64 = input[0];
    if (n64 < 0 or n64 > 8 or length != 1 + 2 * @as(usize, @intCast(n64))) return -1;
    const n: usize = @intCast(n64);
    var release: [max_jobs]i64 = [_]i64{0} ** max_jobs;
    var remaining: [max_jobs]i64 = [_]i64{0} ** max_jobs;
    var attained: [max_jobs]i64 = [_]i64{0} ** max_jobs;
    for (0..n) |job| {
        release[job] = input[1 + 2 * job];
        remaining[job] = input[2 + 2 * job];
        if (release[job] < 0 or release[job] > 16 or remaining[job] < 1 or remaining[job] > 12) return -1;
    }
    if (output_opt == null) return -2;
    var trace: [max_output]u8 = [_]u8{0} ** max_output;
    var time: usize = 0;
    var completed: usize = 0;
    while (completed < n and time < max_output) : (time += 1) {
        var chosen = n;
        for (0..n) |job| {
            if (release[job] <= @as(i64, @intCast(time)) and remaining[job] > 0 and
                (chosen == n or attained[job] < attained[chosen])) chosen = job;
        }
        if (chosen < n) {
            trace[time] = @intCast(chosen + 1);
            attained[chosen] += 1;
            remaining[chosen] -= 1;
            if (remaining[chosen] == 0) completed += 1;
        }
    }
    if (completed != n) return -1;
    if (capacity < time) return -2;
    const output = output_opt.?;
    @memcpy(output[0..time], trace[0..time]);
    return @intCast(time);
}
