#include <stddef.h>
#include <stdint.h>

#define MAX_TEXT_LENGTH 128
#define CHECKSUM_BASE INT64_C(1100000)

int64_t substring_minus(const int64_t *values, size_t length) {
    if (values == NULL || length < 1 || length > MAX_TEXT_LENGTH) return -1;
    for (size_t i = 0; i < length; ++i) if (values[i] < 1 || values[i] > 127) return -1;
    const size_t count = length - 1;
    int64_t checksum = 0;
    for (size_t i = 0; i < count; ++i) checksum += (int64_t)(i + 1) * values[i];
    return (int64_t)count * CHECKSUM_BASE + checksum;
}
