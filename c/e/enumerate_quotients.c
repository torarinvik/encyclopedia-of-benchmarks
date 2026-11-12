#include <stddef.h>
#include <stdint.h>

#define MAX_N INT64_C(100000)

int64_t enumerate_quotients(int64_t value, uint8_t *output, size_t output_capacity) {
    if (value < 1 || value > MAX_N) return -1;
    const uint64_t n = (uint64_t)value;
    size_t count = 0;
    for (uint64_t left = 1; left <= n;) {
        const uint64_t quotient = n / left;
        ++count;
        left = n / quotient + 1;
    }
    const size_t byte_count = (count + 1) * 8;
    if (output == NULL || output_capacity < byte_count) return -2;
    for (size_t byte = 0; byte < 8; ++byte)
        output[byte] = (uint8_t)((uint64_t)count >> (byte * 8));
    size_t index = 0;
    for (uint64_t left = 1; left <= n;) {
        const uint64_t quotient = n / left;
        for (size_t byte = 0; byte < 8; ++byte)
            output[(index + 1) * 8 + byte] = (uint8_t)(quotient >> (byte * 8));
        ++index;
        left = n / quotient + 1;
    }
    return (int64_t)byte_count;
}
