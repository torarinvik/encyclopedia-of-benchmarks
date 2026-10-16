/* Go Problem17: sum byte lengths after splitting on ASCII space. */
#include <stddef.h>
#include <stdint.h>

#define WORD_LENGTH_SUM_MAX_BYTES 4096

int64_t word_length_sum(const int64_t *values, size_t length) {
    if (length > WORD_LENGTH_SUM_MAX_BYTES || (length != 0 && values == NULL)) return -1;
    int64_t total = 0;
    for (size_t index = 0; index < length; ++index) {
        if (values[index] < 0 || values[index] > 255) return -1;
        if (values[index] != 32) ++total;
    }
    return total;
}
