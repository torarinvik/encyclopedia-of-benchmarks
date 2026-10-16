#include <stddef.h>
#include <stdint.h>

#define MAX_REQUESTS 64
#define MAX_CYLINDER_COUNT 128

static void sort_ascending(int64_t *items, size_t count)
{
    for (size_t index = 1; index < count; ++index) {
        const int64_t value = items[index];
        size_t position = index;
        while (position > 0 && items[position - 1] > value) {
            items[position] = items[position - 1];
            --position;
        }
        items[position] = value;
    }
}

int64_t circular_scan_scheduling(const int64_t *values, size_t length,
                                 uint8_t *output, size_t capacity)
{
    if (values == NULL || length < 4 || length > 4 + MAX_REQUESTS) return -1;
    const int64_t max_cylinder = values[0];
    const int64_t start = values[1];
    const int64_t moving_up = values[2];
    const int64_t request_count = values[3];
    if (max_cylinder < 1 || max_cylinder > MAX_CYLINDER_COUNT ||
        start < 0 || start >= max_cylinder || (moving_up != 0 && moving_up != 1) ||
        request_count < 0 || request_count > MAX_REQUESTS ||
        length != 4 + (size_t)request_count) return -1;

    int64_t up[MAX_REQUESTS], down[MAX_REQUESTS];
    size_t up_count = 0, down_count = 0;
    for (size_t index = 0; index < (size_t)request_count; ++index) {
        const int64_t request = values[4 + index];
        if (request < -128 || request > 127) return -1;
        if (moving_up == 1) {
            if (request >= start && request < max_cylinder) up[up_count++] = request;
            else if (request < start) down[down_count++] = request;
        } else {
            if (request <= start) down[down_count++] = request;
            else up[up_count++] = request;
        }
    }
    sort_ascending(up, up_count);
    sort_ascending(down, down_count);

    const size_t output_count = up_count + down_count;
    if (capacity < output_count || (output_count > 0 && output == NULL)) return -2;
    size_t position = 0;
    if (moving_up == 1) {
        for (size_t index = 0; index < up_count; ++index) output[position++] = (uint8_t)((up[index] + 256) % 256);
        for (size_t index = 0; index < down_count; ++index) output[position++] = (uint8_t)((down[index] + 256) % 256);
    } else {
        for (size_t index = down_count; index > 0; --index) output[position++] = (uint8_t)((down[index - 1] + 256) % 256);
        for (size_t index = up_count; index > 0; --index) output[position++] = (uint8_t)((up[index - 1] + 256) % 256);
    }
    return (int64_t)output_count;
}
