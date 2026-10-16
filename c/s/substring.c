#include <stddef.h>
#include <stdint.h>

#define MAX_TEXT_LENGTH 128
#define MAX_REQUESTED_COUNT 64
#define CHECKSUM_BASE INT64_C(300000)

int64_t substring(const int64_t *values, size_t length) {
    if (values == NULL || length < 2 || length > MAX_TEXT_LENGTH + 2) return -1;
    const size_t text_length = length - 2;
    const int64_t start = values[0];
    const int64_t requested = values[1];
    if (start < 0 || (uint64_t)start > text_length || requested < 0 || requested > MAX_REQUESTED_COUNT) return -1;
    for (size_t i = 0; i < text_length; ++i) if (values[i + 2] < 1 || values[i + 2] > 127) return -1;
    const size_t remaining = text_length - (size_t)start;
    size_t count = (size_t)requested;
    if (count == 0 && remaining > 0) count = 1;
    if (count > remaining) count = remaining;
    int64_t checksum = 0;
    for (size_t i = 0; i < count; ++i) checksum += (int64_t)(i + 1) * values[(size_t)start + i + 2];
    return (int64_t)count * CHECKSUM_BASE + checksum;
}
