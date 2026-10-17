const MAX_TASKS: usize = 16;
const MAX_STEPS: usize = 64;
const MAX_INPUT_LENGTH: usize = MAX_TASKS + 3;
const I32_MIN: i64 = -2147483648;
const I32_MAX: i64 = 2147483647;

export fn self_adjusting_scheduling(
    input: [*c]const i64,
    length: usize,
    output: [*c]u8,
    capacity: usize,
) i64 {
    if (input == null or length < 3 or length > MAX_INPUT_LENGTH) return -1;
    const task_count_value = input[0];
    const steps_value = input[1];
    if (task_count_value < 1 or task_count_value > MAX_TASKS or
        steps_value < 0 or steps_value > MAX_STEPS or
        length != @as(usize, @intCast(task_count_value)) + 2) return -1;

    const task_count: usize = @intCast(task_count_value);
    const steps: usize = @intCast(steps_value);
    var priorities: [MAX_TASKS]i64 = undefined;
    var wait_times = [_]i64{0} ** MAX_TASKS;
    var schedule = [_]u8{0} ** MAX_STEPS;
    for (0..task_count) |task| {
        const priority = input[task + 2];
        if (priority < I32_MIN or priority > I32_MAX) return -1;
        priorities[task] = priority;
    }

    for (0..steps) |step| {
        for (0..task_count) |left| {
            for (left + 1..task_count) |right| {
                if (priorities[left] == priorities[right]) return -1;
            }
        }
        var selected: usize = 0;
        for (1..task_count) |task| {
            if (priorities[task] < priorities[selected]) selected = task;
        }
        schedule[step] = @intCast(selected);
        wait_times[selected] += 1;
        const updated_priority = priorities[selected] + wait_times[selected];
        if (updated_priority < I32_MIN or updated_priority > I32_MAX) return -1;
        priorities[selected] = updated_priority;
    }

    if (output == null or capacity < steps) return -2;
    for (0..steps) |step| output[step] = schedule[step];
    return @intCast(steps);
}
