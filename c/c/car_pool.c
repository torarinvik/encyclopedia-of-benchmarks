#include <stddef.h>
#include <stdint.h>

int64_t car_pool(const int64_t *input, size_t length)
{
    if (input == NULL || length < 2 || length > 194) return -1;
    if (input[0] < 0 || input[0] > 1000 || input[1] < 0 || input[1] > 64) return -1;
    const int64_t capacity = input[0];
    const size_t trip_count = (size_t)input[1];
    if (length != 2 + 3 * trip_count) return -1;

    int32_t events[1001] = {0};
    for (size_t trip = 0; trip < trip_count; ++trip) {
        const size_t offset = 2 + 3 * trip;
        const int64_t passengers = input[offset];
        const int64_t origin = input[offset + 1];
        const int64_t destination = input[offset + 2];
        if (passengers < 1 || passengers > 1000 || origin < 0 || origin >= destination || destination > 1000) return -1;
        events[origin] += (int32_t)passengers;
        events[destination] -= (int32_t)passengers;
    }

    int32_t occupants = 0;
    for (size_t position = 0; position < 1000; ++position) {
        occupants += events[position];
        if (occupants > capacity) return 0;
    }
    return 1;
}
