#include <stddef.h>
#include <stdint.h>

static void store_i64_le(uint8_t *output, size_t position, int64_t value)
{
    const uint64_t bits = (uint64_t)value;
    for (size_t byte = 0; byte < 8; ++byte)
        output[position + byte] = (uint8_t)(bits >> (byte * 8));
}

int64_t proportional_fair_scheduling(const int64_t *values, size_t length,
                                      uint8_t *output, size_t output_capacity)
{
    if (values == NULL || length < 2 || length > 131) return -1;
    if (values[0] < 0 || values[0] > 64 || values[1] < 1 || values[1] > 1000000) return -1;
    const size_t process_count = (size_t)values[0];
    const int64_t total_resources = values[1];
    if (length != 2 + 2 * process_count) return -1;

    int64_t name_ids[64], weights[64];
    int64_t total_weight = 0;
    for (size_t process = 0; process < process_count; ++process) {
        const int64_t name_id = values[2 + 2 * process];
        const int64_t weight = values[3 + 2 * process];
        if (name_id < INT32_MIN || name_id > INT32_MAX || weight < 1 || weight > 1000000) return -1;
        name_ids[process] = name_id;
        weights[process] = weight;
        total_weight += weight;
    }

    if (process_count == 0) return 0;
    const size_t required = process_count * 16;
    if (output == NULL || output_capacity < required) return -2;

    for (size_t process = 0; process < process_count; ++process) {
        const double quotient = (double)weights[process] / (double)total_weight;
        const double share = quotient * (double)total_resources;
        const int32_t allocation = (int32_t)share;
        store_i64_le(output, process * 16, name_ids[process]);
        store_i64_le(output, process * 16 + 8, allocation);
    }
    return (int64_t)required;
}
