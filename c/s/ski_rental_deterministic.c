#include <stddef.h>
#include <stdint.h>

enum { MAX_INPUT = 4, MAX_TRIPS = 32 };

int64_t ski_rental_deterministic(const int64_t *input, size_t length,
                                 uint8_t *output, size_t capacity) {
    if (input == NULL || length < 3 || length > MAX_INPUT) return -1;
    const int64_t rent = input[0], purchase = input[1], trips = input[2];
    if (length != 3 || rent < 1 || rent > 32 || purchase < 1 || purchase > 64 ||
        trips < 0 || trips > MAX_TRIPS) return -1;
    const size_t count = (size_t)trips;
    if (output == NULL || capacity < count) return -2;
    uint8_t actions[MAX_TRIPS] = {0};
    const int64_t threshold = purchase / rent;
    for (size_t trip = 0; trip < count; ++trip) {
        if ((int64_t)trip < threshold) actions[trip] = 0;
        else if ((int64_t)trip == threshold) actions[trip] = 1;
        else actions[trip] = 2;
    }
    for (size_t trip = 0; trip < count; ++trip) output[trip] = actions[trip];
    return (int64_t)count;
}
