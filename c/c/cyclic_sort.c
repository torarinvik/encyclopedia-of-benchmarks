#include <stddef.h>
#include <stdint.h>

#define MAX_LENGTH 1024

int64_t cyclic_sort(const int64_t *values, size_t length,
                    uint8_t *output, size_t output_capacity) {
    if (length > MAX_LENGTH || (length > 0 && values == NULL)) return -1;
    uint8_t seen[MAX_LENGTH + 1] = {0};
    for (size_t index = 0; index < length; ++index) {
        const int64_t value = values[index];
        if (value < 1 || value > (int64_t)length || seen[(size_t)value]) return -1;
        seen[(size_t)value] = 1;
    }

    int64_t sorted[MAX_LENGTH];
    for (size_t index = 0; index < length; ++index) sorted[index] = values[index];
    size_t index = 0;
    while (index < length) {
        const size_t destination = (size_t)(sorted[index] - 1);
        if (destination == index) {
            ++index;
        } else {
            const int64_t temporary = sorted[index];
            sorted[index] = sorted[destination];
            sorted[destination] = temporary;
        }
    }

    const size_t output_length = length * 8;
    if (output_length > output_capacity || (output_length > 0 && output == NULL)) return -2;
    for (size_t item = 0; item < length; ++item) {
        const uint64_t bits = (uint64_t)sorted[item];
        for (size_t byte = 0; byte < 8; ++byte)
            output[item * 8 + byte] = (uint8_t)(bits >> (8 * byte));
    }
    return (int64_t)length;
}
