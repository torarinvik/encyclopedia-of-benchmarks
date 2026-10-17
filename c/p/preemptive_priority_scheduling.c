#include <stdbool.h>
#include <stddef.h>
#include <stdint.h>

#define MAX_PROCESSES 8
#define MAX_SCHEDULE_TICKS 80
#define MAX_OUTPUT_WORDS (1 + MAX_SCHEDULE_TICKS)

static void put_i32_le(uint8_t *output, size_t offset, int32_t value)
{
    const uint32_t bits = (uint32_t)value;
    for (size_t byte = 0; byte < 4; ++byte)
        output[offset + byte] = (uint8_t)(bits >> (8 * byte));
}

int64_t preemptive_priority_scheduling(const int32_t *input, size_t length,
                                       uint8_t *output, size_t capacity)
{
    if (input == NULL || length < 1 || length > 1 + 4 * MAX_PROCESSES) return -1;
    const int32_t process_count = input[0];
    if (process_count < 0 || process_count > MAX_PROCESSES ||
        length != 1 + 4 * (size_t)process_count) return -1;

    int32_t ids[MAX_PROCESSES], arrivals[MAX_PROCESSES], remaining[MAX_PROCESSES], priorities[MAX_PROCESSES];
    bool seen_ids[MAX_PROCESSES] = {false};
    for (size_t i = 0; i < (size_t)process_count; ++i) {
        const size_t offset = 1 + 4 * i;
        const int32_t id = input[offset], arrival = input[offset + 1];
        const int32_t burst = input[offset + 2], priority = input[offset + 3];
        if (id < 0 || id >= MAX_PROCESSES || seen_ids[id] || arrival < 0 || arrival > 16 ||
            burst < 1 || burst > 8) return -1;
        for (size_t previous = 0; previous < i; ++previous)
            if (priorities[previous] == priority && arrivals[previous] == arrival) return -1;
        seen_ids[id] = true;
        ids[i] = id;
        arrivals[i] = arrival;
        remaining[i] = burst;
        priorities[i] = priority;
    }

    int32_t schedule[MAX_SCHEDULE_TICKS];
    size_t tick_count = 0, completed = 0;
    while (completed < (size_t)process_count) {
        size_t best = (size_t)process_count;
        for (size_t i = 0; i < (size_t)process_count; ++i) {
            if (remaining[i] <= 0 || arrivals[i] > (int32_t)tick_count) continue;
            if (best == (size_t)process_count || priorities[i] > priorities[best] ||
                (priorities[i] == priorities[best] && arrivals[i] < arrivals[best])) best = i;
        }
        if (best == (size_t)process_count) {
            schedule[tick_count++] = -1;
        } else {
            schedule[tick_count++] = ids[best];
            --remaining[best];
            if (remaining[best] == 0) ++completed;
        }
    }

    const size_t bytes = (1 + tick_count) * 4;
    if (output == NULL || capacity < bytes) return -2;
    uint8_t buffer[MAX_OUTPUT_WORDS * 4];
    put_i32_le(buffer, 0, (int32_t)tick_count);
    for (size_t i = 0; i < tick_count; ++i) put_i32_le(buffer, 4 * (i + 1), schedule[i]);
    for (size_t i = 0; i < bytes; ++i) output[i] = buffer[i];
    return (int64_t)bytes;
}
