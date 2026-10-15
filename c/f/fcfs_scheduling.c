#include <stddef.h>
#include <stdint.h>

static void store_i64_le(uint8_t *output, size_t position, int64_t value)
{
    const uint64_t bits = (uint64_t)value;
    for (size_t byte = 0; byte < 8; ++byte)
        output[position + byte] = (uint8_t)(bits >> (byte * 8));
}

int64_t fcfs_scheduling(const int64_t *values, size_t length,
                        uint8_t *output, size_t output_capacity)
{
    if (values == NULL || length < 1 || length > 193) return -2;
    if (values[0] < 0 || values[0] > 64) return -2;
    const size_t count = (size_t)values[0];
    if (length != 1 + 3 * count) return -2;

    int64_t ids[64], arrivals[64], bursts[64];
    size_t order[64];
    for (size_t i = 0; i < count; ++i) {
        const int64_t id = values[1 + 3 * i];
        const int64_t arrival = values[2 + 3 * i];
        const int64_t burst = values[3 + 3 * i];
        if (id < 0 || id > 63 || arrival < 0 || arrival > 1000000 || burst < 1 || burst > 1000000)
            return -2;
        for (size_t previous = 0; previous < i; ++previous)
            if (ids[previous] == id) return -2;
        ids[i] = id;
        arrivals[i] = arrival;
        bursts[i] = burst;
        order[i] = i;
    }

    for (size_t i = 1; i < count; ++i) {
        const size_t key = order[i];
        size_t j = i;
        while (j > 0 && (arrivals[order[j - 1]] > arrivals[key] ||
               (arrivals[order[j - 1]] == arrivals[key] && ids[order[j - 1]] > ids[key]))) {
            order[j] = order[j - 1];
            --j;
        }
        order[j] = key;
    }

    const size_t required = count * 48;
    if (output_capacity < required || (required != 0 && output == NULL)) return -2;
    int64_t elapsed = 0;
    for (size_t position = 0; position < count; ++position) {
        const size_t i = order[position];
        if (elapsed < arrivals[i]) elapsed = arrivals[i];
        const int64_t completion = elapsed + bursts[i];
        const int64_t turnaround = completion - arrivals[i];
        const int64_t waiting = turnaround - bursts[i];
        const int64_t fields[6] = {ids[i], arrivals[i], bursts[i], completion, turnaround, waiting};
        for (size_t field = 0; field < 6; ++field)
            store_i64_le(output, position * 48 + field * 8, fields[field]);
        elapsed = completion;
    }
    return (int64_t)count;
}
