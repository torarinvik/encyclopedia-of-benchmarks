#include <stddef.h>
#include <stdint.h>

#define MAX_TEXT_LENGTH 128
#define CHECKSUM_BASE INT64_C(1100000)

int64_t substring_end(const int64_t *values, size_t length) {
    if (values == NULL || length < 1 || length > MAX_TEXT_LENGTH + 1) return -1;
    const size_t text_length = length - 1;
    const int64_t start = values[0];
    if (start < 0 || (uint64_t)start > text_length) return -1;
    for (size_t i = 0; i < text_length; ++i) if (values[i + 1] < 1 || values[i + 1] > 127) return -1;
    const size_t count = text_length - (size_t)start;
    int64_t checksum = 0;
    for (size_t i = 0; i < count; ++i) checksum += (int64_t)(i + 1) * values[(size_t)start + i + 1];
    return (int64_t)count * CHECKSUM_BASE + checksum;
}
