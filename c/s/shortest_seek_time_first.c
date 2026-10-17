#include <stdbool.h>
#include <stddef.h>
#include <stdint.h>
#define MAX_REQUESTS 64

int64_t shortest_seek_time_first(const int64_t *values, size_t length,
                                 uint8_t *output, size_t capacity)
{
    if (values == NULL || length < 2 || length > 2 + MAX_REQUESTS) return -1;
    const int64_t initial_track = values[0], request_count = values[1];
    if (initial_track < 0 || initial_track > 255 || request_count < 0 ||
        request_count > MAX_REQUESTS || length != 2 + (size_t)request_count) return -1;
    for (size_t i = 0; i < (size_t)request_count; ++i)
        if (values[2 + i] < 0 || values[2 + i] > 255) return -1;
    if (output == NULL || capacity < (size_t)request_count) return -2;
    bool serviced[MAX_REQUESTS] = { false };
    int64_t current = initial_track;
    for (size_t step = 0; step < (size_t)request_count; ++step) {
        size_t best = MAX_REQUESTS;
        int64_t best_distance = 256;
        for (size_t i = 0; i < (size_t)request_count; ++i) {
            if (serviced[i]) continue;
            int64_t distance = current - values[2 + i];
            if (distance < 0) distance = -distance;
            if (distance < best_distance) { best = i; best_distance = distance; }
        }
        int64_t selected = values[2 + best];
        output[step] = (uint8_t)selected;
        serviced[best] = true;
        current = selected;
    }
    return request_count;
}
