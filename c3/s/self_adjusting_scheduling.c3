module self_adjusting_scheduling;

const usz MAX_TASKS = 16;
const usz MAX_STEPS = 64;
const usz MAX_INPUT_LENGTH = MAX_TASKS + 3;

fn long self_adjusting_scheduling(long* input, usz length, uint8* output, usz capacity)
    @export("self_adjusting_scheduling") {
    if (input == null || length < 3 || length > MAX_INPUT_LENGTH) return -1;
    long task_count_value = input[0], steps_value = input[1];
    if (task_count_value < 1 || task_count_value > 16 ||
        steps_value < 0 || steps_value > 64 ||
        length != (usz)task_count_value + 2) return -1;

    usz task_count = (usz)task_count_value, steps = (usz)steps_value;
    long priorities[16];
    long wait_times[16] = {0};
    uint8 schedule[64];
    for (usz task = 0; task < task_count; task++) {
        long priority = input[task + 2];
        if (priority < -2147483648 || priority > 2147483647) return -1;
        priorities[task] = priority;
    }

    for (usz step = 0; step < steps; step++) {
        for (usz left = 0; left < task_count; left++) {
            for (usz right = left + 1; right < task_count; right++) {
                if (priorities[left] == priorities[right]) return -1;
            }
        }
        usz selected = 0;
        for (usz task = 1; task < task_count; task++) {
            if (priorities[task] < priorities[selected]) selected = task;
        }
        schedule[step] = (uint8)selected;
        wait_times[selected]++;
        long updated_priority = priorities[selected] + wait_times[selected];
        if (updated_priority < -2147483648 || updated_priority > 2147483647) return -1;
        priorities[selected] = updated_priority;
    }

    if (output == null || capacity < steps) return -2;
    for (usz step = 0; step < steps; step++) output[step] = schedule[step];
    return (long)steps;
}
