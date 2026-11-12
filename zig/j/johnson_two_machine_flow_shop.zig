const MAX_JOBS: usize = 8;
const MAX_TIME: i64 = 1000;

export fn johnson_two_machine_flow_shop(input_opt: ?[*]const i64, length: usize) i64 {
    if (input_opt == null or length < 1) return -1;
    const input = input_opt.?;
    if (input[0] < 1 or input[0] > @as(i64, @intCast(MAX_JOBS))) return -1;
    const count: usize = @intCast(input[0]);
    if (length != 1 + 2 * count) return -1;
    var first = [_]i64{0} ** MAX_JOBS;
    var second = [_]i64{0} ** MAX_JOBS;
    var early = [_]usize{0} ** MAX_JOBS;
    var late = [_]usize{0} ** MAX_JOBS;
    var early_count: usize = 0;
    var late_count: usize = 0;
    for (0..count) |job| {
        first[job] = input[1 + 2 * job];
        second[job] = input[2 + 2 * job];
        if (first[job] < 0 or first[job] > MAX_TIME or second[job] < 0 or second[job] > MAX_TIME) return -1;
        const is_early = first[job] < second[job];
        var position = if (is_early) early_count else late_count;
        while (position > 0) {
            const previous = if (is_early) early[position - 1] else late[position - 1];
            const comes_before = if (is_early)
                (first[job] < first[previous] or (first[job] == first[previous] and job < previous))
            else
                (second[job] > second[previous] or (second[job] == second[previous] and job < previous));
            if (!comes_before) break;
            if (is_early) early[position] = previous else late[position] = previous;
            position -= 1;
        }
        if (is_early) {
            early[position] = job;
            early_count += 1;
        } else {
            late[position] = job;
            late_count += 1;
        }
    }
    var first_finish: i64 = 0;
    var second_finish: i64 = 0;
    for (0..count) |index| {
        const job = if (index < early_count) early[index] else late[index - early_count];
        first_finish += first[job];
        second_finish = @max(second_finish, first_finish) + second[job];
    }
    return second_finish;
}
