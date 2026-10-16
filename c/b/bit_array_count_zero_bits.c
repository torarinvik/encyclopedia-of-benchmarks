#include <stddef.h>
#include <stdint.h>

#define MAX_BITS 4096

int64_t bit_array_count_zero_bits(const int64_t *values, size_t length) {
    if (length > MAX_BITS || (length != 0 && values == NULL)) return -1;
    int64_t zero_count = 0;
    for (size_t index = 0; index < length; ++index) {
        if (values[index] != 0 && values[index] != 1) return -1;
        if (values[index] == 0) ++zero_count;
    }
    return zero_count;
}
