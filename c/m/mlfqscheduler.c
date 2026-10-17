#include <stddef.h>
#include <stdint.h>

#define MAX_LEVELS 4
#define MAX_PROCESSES 16

static void put_i64_le(uint8_t *output, size_t offset, int64_t value) {
    uint64_t bits = (uint64_t)value;
    for (size_t byte = 0; byte < 8; ++byte) output[offset + byte] = (uint8_t)(bits >> (8 * byte));
}

int64_t mlfqscheduler(const int64_t *input, size_t length, uint8_t *output, size_t output_capacity) {
    if (input == NULL || length < 2 || length > 55) return -1;
    int64_t levels_value = input[0], process_count_value = input[1];
    if (levels_value < 1 || levels_value > MAX_LEVELS || process_count_value < 0 || process_count_value > MAX_PROCESSES) return -1;
    size_t levels = (size_t)levels_value, process_count = (size_t)process_count_value;
    if (length != 2 + levels + 3 * process_count) return -1;
    int64_t quanta[MAX_LEVELS], pids[MAX_PROCESSES], remaining[MAX_PROCESSES];
    for (size_t level = 0; level < levels; ++level) {
        quanta[level] = input[2 + level];
        if (quanta[level] < 1 || quanta[level] > 32) return -1;
    }
    size_t process_offset = 2 + levels;
    for (size_t i = 0; i < process_count; ++i) {
        int64_t pid = input[process_offset + 3 * i];
        int64_t burst = input[process_offset + 3 * i + 1];
        int64_t arrival = input[process_offset + 3 * i + 2];
        if (pid < INT32_MIN || pid > INT32_MAX || burst < 0 || burst > 1000 || arrival < 0 || arrival > 1000000) return -1;
        pids[i] = pid;
        remaining[i] = burst;
    }

    size_t queues[MAX_LEVELS * MAX_PROCESSES] = {0};
    size_t queue_counts[MAX_LEVELS] = {0};
    for (size_t i = 0; i < process_count; ++i) queues[i] = i;
    queue_counts[0] = process_count;
    int64_t completion_pids[MAX_PROCESSES], completion_times[MAX_PROCESSES];
    size_t completions = 0;
    int64_t current_time = 0;
    for (;;) {
        size_t active = 0;
        for (size_t level = 0; level < levels; ++level) active += queue_counts[level];
        if (active == 0) break;
        for (size_t level = 0; level < levels; ++level) {
            size_t base = level * MAX_PROCESSES;
            size_t queued = queue_counts[level];
            if (queued == 0) continue;
            size_t process = queues[base];
            for (size_t j = 1; j < queued; ++j) queues[base + j - 1] = queues[base + j];
            --queue_counts[level];
            int64_t slice = quanta[level] < remaining[process] ? quanta[level] : remaining[process];
            current_time += slice;
            remaining[process] -= slice;
            if (remaining[process] == 0) {
                completion_pids[completions] = pids[process];
                completion_times[completions++] = current_time;
            } else {
                size_t destination = level + 1 < levels ? level + 1 : level;
                size_t destination_base = destination * MAX_PROCESSES;
                queues[destination_base + queue_counts[destination]++] = process;
            }
        }
    }

    size_t elements = 2 + 2 * completions, required = elements * 8;
    if (output == NULL || output_capacity < required) return -2;
    put_i64_le(output, 0, current_time);
    put_i64_le(output, 8, (int64_t)completions);
    for (size_t i = 0; i < completions; ++i) {
        put_i64_le(output, 16 + 16 * i, completion_pids[i]);
        put_i64_le(output, 24 + 16 * i, completion_times[i]);
    }
    return (int64_t)elements;
}
