/* Simulate the bounded Java self-adjusting task queue. */
#include <stddef.h>
#include <stdint.h>

#define MAX_TASKS 16
#define MAX_STEPS 64
#define MAX_INPUT_LENGTH (MAX_TASKS + 3)

int64_t self_adjusting_scheduling(const int64_t *input, size_t length,
                                  uint8_t *output, size_t capacity) {
    if (input == NULL || length < 3 || length > MAX_INPUT_LENGTH) return -1;

    const int64_t task_count_value = input[0];
    const int64_t steps_value = input[1];
    if (task_count_value < 1 || task_count_value > MAX_TASKS ||
        steps_value < 0 || steps_value > MAX_STEPS ||
        length != (size_t)task_count_value + 2) return -1;

    const size_t task_count = (size_t)task_count_value;
    const size_t steps = (size_t)steps_value;
    int64_t priorities[MAX_TASKS];
    int64_t wait_times[MAX_TASKS] = {0};
    uint8_t schedule[MAX_STEPS];
    for (size_t task = 0; task < task_count; ++task) {
        const int64_t priority = input[task + 2];
        if (priority < INT32_MIN || priority > INT32_MAX) return -1;
        priorities[task] = priority;
    }

    for (size_t step = 0; step < steps; ++step) {
        for (size_t left = 0; left < task_count; ++left) {
            for (size_t right = left + 1; right < task_count; ++right) {
                if (priorities[left] == priorities[right]) return -1;
            }
        }

        size_t selected = 0;
        for (size_t task = 1; task < task_count; ++task) {
            if (priorities[task] < priorities[selected]) selected = task;
        }
        schedule[step] = (uint8_t)selected;
        ++wait_times[selected];
        const int64_t updated_priority = priorities[selected] + wait_times[selected];
        if (updated_priority < INT32_MIN || updated_priority > INT32_MAX) return -1;
        priorities[selected] = updated_priority;
    }

    if (output == NULL || capacity < steps) return -2;
    for (size_t step = 0; step < steps; ++step) output[step] = schedule[step];
    return (int64_t)steps;
}
