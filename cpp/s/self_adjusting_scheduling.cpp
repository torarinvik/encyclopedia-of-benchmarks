/* Simulate the bounded Java self-adjusting task queue. */
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_tasks = 16;
constexpr std::size_t max_steps = 64;
constexpr std::size_t max_input_length = max_tasks + 3;
}

extern "C" std::int64_t self_adjusting_scheduling(
    const std::int64_t *input, std::size_t length, std::uint8_t *output,
    std::size_t capacity) {
    if (input == nullptr || length < 3 || length > max_input_length) return -1;

    const std::int64_t task_count_value = input[0];
    const std::int64_t steps_value = input[1];
    if (task_count_value < 1 || task_count_value > 16 ||
        steps_value < 0 || steps_value > 64 ||
        length != static_cast<std::size_t>(task_count_value) + 2) return -1;

    const auto task_count = static_cast<std::size_t>(task_count_value);
    const auto steps = static_cast<std::size_t>(steps_value);
    std::int64_t priorities[max_tasks];
    std::int64_t wait_times[max_tasks] = {};
    std::uint8_t schedule[max_steps];
    for (std::size_t task = 0; task < task_count; ++task) {
        const auto priority = input[task + 2];
        if (priority < INT32_MIN || priority > INT32_MAX) return -1;
        priorities[task] = priority;
    }

    for (std::size_t step = 0; step < steps; ++step) {
        for (std::size_t left = 0; left < task_count; ++left) {
            for (std::size_t right = left + 1; right < task_count; ++right) {
                if (priorities[left] == priorities[right]) return -1;
            }
        }
        std::size_t selected = 0;
        for (std::size_t task = 1; task < task_count; ++task) {
            if (priorities[task] < priorities[selected]) selected = task;
        }
        schedule[step] = static_cast<std::uint8_t>(selected);
        ++wait_times[selected];
        const auto updated_priority = priorities[selected] + wait_times[selected];
        if (updated_priority < INT32_MIN || updated_priority > INT32_MAX) return -1;
        priorities[selected] = updated_priority;
    }

    if (output == nullptr || capacity < steps) return -2;
    for (std::size_t step = 0; step < steps; ++step) output[step] = schedule[step];
    return static_cast<std::int64_t>(steps);
}
