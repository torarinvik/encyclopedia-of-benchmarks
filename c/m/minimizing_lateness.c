#include <stddef.h>
#include <stdint.h>

#define ML_MAX_JOBS 64
#define ML_MAX_INPUT (1 + 2 * ML_MAX_JOBS)
#define ML_MAX_OUTPUT (4 + 12 * ML_MAX_JOBS)

typedef struct {
    int32_t processing;
    int32_t deadline;
    int32_t original_index;
    int32_t start_time;
    int32_t lateness;
} ml_job;

static void ml_write_i32(uint8_t *output, size_t offset, int32_t value)
{
    const uint32_t bits = (uint32_t)value;
    for (size_t byte = 0; byte < 4; ++byte)
        output[offset + byte] = (uint8_t)(bits >> (8 * byte));
}

int64_t minimizing_lateness(const int64_t *input, size_t length,
                            uint8_t *output, size_t output_capacity)
{
    if (input == NULL || length < 1 || length > ML_MAX_INPUT) return -1;
    const int64_t count_value = input[0];
    if (count_value < 0 || count_value > ML_MAX_JOBS || length != 1 + 2 * (size_t)count_value) return -1;
    const size_t count = (size_t)count_value;
    ml_job jobs[ML_MAX_JOBS];
    int64_t total_processing = 0;
    for (size_t i = 0; i < count; ++i) {
        const int64_t processing = input[1 + 2 * i];
        const int64_t deadline = input[2 + 2 * i];
        if (processing < 0 || processing > INT32_MAX || deadline < 0 || deadline > INT32_MAX) return -1;
        total_processing += processing;
        if (total_processing > INT32_MAX) return -1;
        jobs[i] = (ml_job){(int32_t)processing, (int32_t)deadline, (int32_t)i, 0, 0};
    }

    /* Stable insertion sort preserves the source order for equal deadlines. */
    for (size_t i = 1; i < count; ++i) {
        const ml_job item = jobs[i];
        size_t position = i;
        while (position > 0 && jobs[position - 1].deadline > item.deadline) {
            jobs[position] = jobs[position - 1];
            --position;
        }
        jobs[position] = item;
    }

    int64_t start_time = 0;
    for (size_t i = 0; i < count; ++i) {
        jobs[i].start_time = (int32_t)start_time;
        const int64_t finish_time = start_time + jobs[i].processing;
        const int64_t late = finish_time - jobs[i].deadline;
        jobs[i].lateness = (int32_t)(late > 0 ? late : 0);
        start_time = finish_time;
    }

    uint8_t payload[ML_MAX_OUTPUT];
    ml_write_i32(payload, 0, (int32_t)count);
    for (size_t i = 0; i < count; ++i) {
        const size_t offset = 4 + 12 * i;
        ml_write_i32(payload, offset, jobs[i].original_index);
        ml_write_i32(payload, offset + 4, jobs[i].start_time);
        ml_write_i32(payload, offset + 8, jobs[i].lateness);
    }
    const size_t needed = 4 + 12 * count;
    if (output == NULL || output_capacity < needed) return -2;
    for (size_t i = 0; i < needed; ++i) output[i] = payload[i];
    return (int64_t)needed;
}
