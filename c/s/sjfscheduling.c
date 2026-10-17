#include <stddef.h>
#include <stdint.h>

#define MAX_INPUT_LENGTH 130u
#define MAX_PROCESSES 64u
#define MAX_OUTPUT_BYTES 256u

static void write_i32_le(uint8_t *output, size_t offset, int32_t value)
{
    uint32_t bits = (uint32_t)value;
    for (size_t byte = 0; byte < 4u; ++byte) {
        output[offset + byte] = (uint8_t)bits;
        bits >>= 8u;
    }
}

int64_t sjfscheduling(const int32_t *input, size_t length,
                      uint8_t *output, size_t output_capacity)
{
    if (input == NULL || length < 1u || length > MAX_INPUT_LENGTH) return -1;
    const int32_t process_count_value = input[0];
    if (process_count_value < 0 || process_count_value > (int32_t)MAX_PROCESSES
        || length != 1u + 2u * (size_t)process_count_value) return -1;
    const size_t process_count = (size_t)process_count_value;

    int32_t arrivals[MAX_PROCESSES], bursts[MAX_PROCESSES], order[MAX_PROCESSES];
    uint8_t completed[MAX_PROCESSES] = {0};
    size_t cursor = 1u;
    for (size_t index = 0; index < process_count; ++index) {
        const int32_t arrival = input[cursor++];
        const int32_t burst = input[cursor++];
        if (arrival < 0 || arrival > 255 || burst < 1 || burst > 255) return -1;
        arrivals[index] = arrival;
        bursts[index] = burst;
    }

    int32_t current_time = 0;
    size_t scheduled = 0u;
    while (scheduled < process_count) {
        size_t best = process_count;
        for (size_t index = 0; index < process_count; ++index) {
            if (completed[index] != 0u || arrivals[index] > current_time) continue;
            if (best == process_count || bursts[index] < bursts[best]
                || (bursts[index] == bursts[best]
                    && (arrivals[index] < arrivals[best]
                        || (arrivals[index] == arrivals[best] && index < best)))) {
                best = index;
            }
        }
        if (best == process_count) {
            ++current_time;
        } else {
            order[scheduled++] = (int32_t)best;
            completed[best] = 1u;
            current_time += bursts[best];
        }
    }

    const size_t output_bytes = process_count * 4u;
    if (output == NULL || output_capacity < output_bytes) return -2;
    for (size_t index = 0; index < process_count; ++index)
        write_i32_le(output, index * 4u, order[index]);
    return (int64_t)output_bytes;
}
