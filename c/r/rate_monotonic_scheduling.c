#include <stddef.h>
#include <stdint.h>

#define MAX_TASKS 8
#define MAX_INPUT 17
#define MAX_OUTPUT_BYTES 80

static void store_i64_le(uint8_t *output, size_t offset, int64_t value)
{
    uint64_t bits = (uint64_t)value;
    for (size_t byte = 0; byte < 8; ++byte) {
        output[offset + byte] = (uint8_t)(bits & 255U);
        bits >>= 8;
    }
}

int64_t rate_monotonic_scheduling(const int64_t *input, size_t length,
                                  uint8_t *output, size_t capacity)
{
    if (input == NULL || length < 3 || length > MAX_INPUT) return -1;
    int64_t count_value = input[0];
    if (count_value < 1 || count_value > MAX_TASKS || length != 1 + 2 * (size_t)count_value) return -1;
    size_t count = (size_t)count_value;
    int64_t execution[MAX_TASKS] = {0};
    int64_t period[MAX_TASKS] = {0};
    size_t order[MAX_TASKS] = {0};
    int64_t response[MAX_TASKS];
    for (size_t task = 0; task < count; ++task) {
        execution[task] = input[1 + 2 * task];
        period[task] = input[2 + 2 * task];
        if (execution[task] < 1 || execution[task] > 16 || period[task] < 1 || period[task] > 32) return -1;
        order[task] = task;
        response[task] = -1;
    }
    for (size_t index = 1; index < count; ++index) {
        size_t key = order[index];
        size_t position = index;
        while (position > 0 && (period[order[position - 1]] > period[key] ||
               (period[order[position - 1]] == period[key] && order[position - 1] > key))) {
            order[position] = order[position - 1];
            --position;
        }
        order[position] = key;
    }

    int64_t schedulable = 1;
    int64_t failed_task = -1;
    for (size_t rank = 0; rank < count; ++rank) {
        size_t target = order[rank];
        int64_t remaining_target = execution[target];
        int64_t active[MAX_TASKS] = {0};
        int64_t elapsed = 0;
        while (remaining_target > 0 && elapsed < period[target]) {
            for (size_t higher_rank = 0; higher_rank < rank; ++higher_rank) {
                size_t higher = order[higher_rank];
                if (elapsed % period[higher] == 0) active[higher] += execution[higher];
            }
            size_t selected = MAX_TASKS;
            for (size_t higher_rank = 0; higher_rank < rank; ++higher_rank) {
                size_t higher = order[higher_rank];
                if (active[higher] > 0) { selected = higher; break; }
            }
            if (selected < MAX_TASKS) --active[selected];
            else --remaining_target;
            ++elapsed;
        }
        if (remaining_target > 0) {
            schedulable = 0;
            failed_task = (int64_t)target;
            break;
        }
        response[target] = elapsed;
    }

    size_t output_bytes = 8 * (count + 2);
    if (output == NULL || capacity < output_bytes) return -2;
    uint8_t staged[MAX_OUTPUT_BYTES] = {0};
    store_i64_le(staged, 0, schedulable);
    store_i64_le(staged, 8, failed_task);
    for (size_t task = 0; task < count; ++task) store_i64_le(staged, 8 * (task + 2), response[task]);
    for (size_t byte = 0; byte < output_bytes; ++byte) output[byte] = staged[byte];
    return (int64_t)output_bytes;
}
