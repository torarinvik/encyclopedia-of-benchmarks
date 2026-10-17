package self_adjusting_scheduling

import "core:c"

MAX_TASKS :: 16
MAX_STEPS :: 64
MAX_INPUT_LENGTH :: MAX_TASKS + 3

self_adjusting_scheduling :: proc "c" (input: [^]i64, length: c.size_t,
    output: [^]u8, capacity: c.size_t) -> i64 {
    if input == nil || length < 3 || length > c.size_t(MAX_INPUT_LENGTH) do return -1
    task_count_value, steps_value := input[0], input[1]
    if task_count_value < 1 || task_count_value > MAX_TASKS ||
       steps_value < 0 || steps_value > MAX_STEPS ||
       length != c.size_t(task_count_value) + 2 do return -1

    task_count, steps := int(task_count_value), int(steps_value)
    priorities: [MAX_TASKS]i64
    wait_times: [MAX_TASKS]i64
    schedule: [MAX_STEPS]u8
    for task in 0..<task_count {
        priority := input[task + 2]
        if priority < -2147483648 || priority > 2147483647 do return -1
        priorities[task] = priority
        wait_times[task] = 0
    }

    for step in 0..<steps {
        for left in 0..<task_count {
            for right in left + 1..<task_count {
                if priorities[left] == priorities[right] do return -1
            }
        }
        selected := 0
        for task in 1..<task_count {
            if priorities[task] < priorities[selected] do selected = task
        }
        schedule[step] = u8(selected)
        wait_times[selected] += 1
        updated_priority := priorities[selected] + wait_times[selected]
        if updated_priority < -2147483648 || updated_priority > 2147483647 do return -1
        priorities[selected] = updated_priority
    }

    if output == nil || capacity < c.size_t(steps) do return -2
    for step in 0..<steps do output[step] = schedule[step]
    return i64(steps)
}
